#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/sync-custom-agents.sh [--force] [--hooks] [--source PATH] [--target PATH] [--codex-home PATH] [--support-home PATH] [--obsidian-vault PATH] [--obsidian-projects-folder PATH] [--import-claude-obsidian]

Installs Codex custom agents from this pack into:
  ${CODEX_HOME:-$HOME/.codex}/agents

Use --hooks to also install global hooks.json and the hook support files needed
by those hooks. Use --force to replace existing installed files.
Use --obsidian-vault to configure best-effort Obsidian autologging for hooks.
Use --import-claude-obsidian to read OBSIDIAN_VAULT_PATH and
OBSIDIAN_PROJECTS_FOLDER from ~/.claude/settings.json.
USAGE
}

force=0
install_hooks=0
source_dir=""
target_dir=""
codex_home="${CODEX_HOME:-$HOME/.codex}"
support_home=""
obsidian_vault=""
obsidian_projects_folder=""
import_claude_obsidian=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --hooks)
      install_hooks=1
      shift
      ;;
    --source)
      source_dir="${2:?Missing value for --source}"
      shift 2
      ;;
    --target)
      target_dir="${2:?Missing value for --target}"
      shift 2
      ;;
    --codex-home)
      codex_home="${2:?Missing value for --codex-home}"
      shift 2
      ;;
    --support-home)
      support_home="${2:?Missing value for --support-home}"
      shift 2
      ;;
    --obsidian-vault)
      obsidian_vault="${2:?Missing value for --obsidian-vault}"
      shift 2
      ;;
    --obsidian-projects-folder)
      obsidian_projects_folder="${2:?Missing value for --obsidian-projects-folder}"
      shift 2
      ;;
    --import-claude-obsidian)
      import_claude_obsidian=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$target_dir" ]]; then
  target_dir="$codex_home/agents"
fi

if [[ -z "$support_home" ]]; then
  support_home="$codex_home/agent-pack"
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
pack_root="$(cd "$script_dir/.." && pwd -P)"

obsidian_config_helper="$pack_root/scripts/obsidian-config.sh"
if [[ -f "$obsidian_config_helper" ]]; then
  # shellcheck source=scripts/obsidian-config.sh
  source "$obsidian_config_helper"
fi

first_existing_dir() {
  local candidate
  for candidate in "$@"; do
    if [[ -n "$candidate" && -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

first_existing_file() {
  local candidate
  for candidate in "$@"; do
    if [[ -n "$candidate" && -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

copy_path() {
  local source="$1"
  local destination="$2"

  if [[ ! -e "$source" ]]; then
    echo "[skip] missing source: $source"
    return 0
  fi

  if [[ -e "$destination" ]]; then
    if [[ "$force" -ne 1 ]]; then
      echo "[--] exists: $destination"
      return 0
    fi
    rm -rf -- "$destination"
  fi

  mkdir -p "$(dirname -- "$destination")"
  cp -R -- "$source" "$destination"
  echo "[ok] installed: $destination"
}

copy_dir_children() {
  local source_dir="$1"
  local destination_dir="$2"
  mkdir -p "$destination_dir"

  if [[ ! -d "$source_dir" ]]; then
    echo "[skip] missing source directory: $source_dir"
    return 0
  fi

  while IFS= read -r -d '' item; do
    copy_path "$item" "$destination_dir/$(basename "$item")"
  done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -print0)
}

if [[ -z "$source_dir" ]]; then
  source_dir="$(first_existing_dir "$pack_root/custom-agents" "$pack_root/.codex/agents" || true)"
fi

if [[ -z "$source_dir" || ! -d "$source_dir" ]]; then
  echo "Could not find custom agents. Pass --source <path>." >&2
  exit 1
fi

mkdir -p "$target_dir"
agent_count=0
while IFS= read -r -d '' file; do
  copy_path "$file" "$target_dir/$(basename "$file")"
  agent_count=$((agent_count + 1))
done < <(find "$source_dir" -maxdepth 1 -type f -name '*.toml' -print0)

if [[ "$agent_count" -eq 0 ]]; then
  echo "No custom agent TOML files found in: $source_dir" >&2
  exit 1
fi

obsidian_configured=0
if [[ "$import_claude_obsidian" -eq 1 ]]; then
  if ! declare -F codex_agent_pack_read_claude_obsidian_config >/dev/null; then
    echo "[!!] cannot import Claude Obsidian config: missing scripts/obsidian-config.sh" >&2
    exit 1
  fi
  if [[ -z "$obsidian_vault" ]]; then
    obsidian_vault="$(codex_agent_pack_read_claude_obsidian_config OBSIDIAN_VAULT_PATH || true)"
  fi
  if [[ -z "$obsidian_projects_folder" ]]; then
    obsidian_projects_folder="$(codex_agent_pack_read_claude_obsidian_config OBSIDIAN_PROJECTS_FOLDER || true)"
  fi
fi

hooks_json_source=""
hook_dir_source=""
scripts_source=""
if [[ "$install_hooks" -eq 1 ]]; then
  hooks_json_source="$(first_existing_file "$pack_root/hooks/global-hooks.json" "$pack_root/.codex/global-hooks.json" || true)"
  hook_dir_source="$(first_existing_dir "$pack_root/hooks" "$pack_root/.codex/hooks" || true)"
  scripts_source="$(first_existing_dir "$pack_root/scripts" || true)"

  if [[ -z "$hooks_json_source" ]]; then
    echo "Could not find global hooks config in this pack." >&2
    exit 1
  fi

  copy_path "$hooks_json_source" "$codex_home/hooks.json"

  if [[ -n "$hook_dir_source" ]]; then
    copy_dir_children "$hook_dir_source" "$support_home/hooks"
  fi

  if [[ -n "$scripts_source" ]]; then
    copy_dir_children "$scripts_source" "$support_home/scripts"
  fi

  for file in AGENTS.md PORTING-NOTES.md LICENSE; do
    if [[ -f "$pack_root/$file" ]]; then
      copy_path "$pack_root/$file" "$support_home/$file"
    fi
  done
fi

if [[ -n "$obsidian_vault" ]]; then
  if ! declare -F codex_agent_pack_write_obsidian_config >/dev/null; then
    echo "[!!] cannot write Obsidian config: missing scripts/obsidian-config.sh" >&2
    exit 1
  fi
  codex_agent_pack_write_obsidian_config "$support_home/obsidian.env" "$obsidian_vault" "${obsidian_projects_folder:-Codex/Projects}"
  echo "[ok] obsidian config: $support_home/obsidian.env"
  obsidian_configured=1
elif [[ "$import_claude_obsidian" -eq 1 ]]; then
  echo "[--] Claude Obsidian config not found; Obsidian autologging not configured."
fi

cat <<EOF

Codex custom agents synced.

Source:        $source_dir
Custom agents: $target_dir
Hooks:         $(if [[ "$install_hooks" -eq 1 ]]; then echo "$codex_home/hooks.json"; else echo "not installed"; fi)
Support copy:  $(if [[ "$install_hooks" -eq 1 ]]; then echo "$support_home"; else echo "not updated"; fi)
Obsidian:      $(if [[ "$obsidian_configured" -eq 1 ]]; then echo "$support_home/obsidian.env"; else echo "not configured"; fi)

Restart Codex or start a new session so it reloads custom agents.
EOF

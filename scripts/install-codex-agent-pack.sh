#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/install-codex-agent-pack.sh [--force] [--hooks] [--codex-home PATH] [--skills-home PATH] [--agent-pack-home PATH] [--obsidian-vault PATH] [--obsidian-projects-folder PATH] [--import-claude-obsidian]

Installs this pack for the current user:
- skills -> $HOME/.agents/skills
- custom agents -> ${CODEX_HOME:-$HOME/.codex}/agents
- support copy -> ${CODEX_HOME:-$HOME/.codex}/agent-pack
- optional global hooks -> ${CODEX_HOME:-$HOME/.codex}/hooks.json

Use --force to replace existing installed files.
Use --hooks to install the global hooks.json. This refuses to replace an
existing hooks.json unless --force is also supplied.
Use --obsidian-vault to configure best-effort Obsidian autologging for hooks.
Use --import-claude-obsidian to read OBSIDIAN_VAULT_PATH and
OBSIDIAN_PROJECTS_FOLDER from ~/.claude/settings.json.
USAGE
}

force=0
install_hooks=0
codex_home="${CODEX_HOME:-$HOME/.codex}"
skills_home="${CODEX_GLOBAL_SKILLS_HOME:-$HOME/.agents/skills}"
agent_pack_home="${CODEX_AGENT_PACK_HOME:-}"
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
    --codex-home)
      codex_home="${2:?Missing value for --codex-home}"
      shift 2
      ;;
    --skills-home)
      skills_home="${2:?Missing value for --skills-home}"
      shift 2
      ;;
    --agent-pack-home)
      agent_pack_home="${2:?Missing value for --agent-pack-home}"
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

if [[ -z "$agent_pack_home" ]]; then
  agent_pack_home="$codex_home/agent-pack"
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

mkdir -p "$codex_home" "$skills_home" "$codex_home/agents" "$agent_pack_home"

skills_source="$(first_existing_dir "$pack_root/.agents/skills" "$pack_root/skills" || true)"
agents_source="$(first_existing_dir "$pack_root/.codex/agents" "$pack_root/custom-agents" || true)"
hook_scripts_source="$(first_existing_dir "$pack_root/.codex/hooks" "$pack_root/hooks" || true)"
global_hooks_source="$(first_existing_file "$pack_root/.codex/global-hooks.json" "$pack_root/hooks/global-hooks.json" || true)"

copy_path "$pack_root/AGENTS.md" "$agent_pack_home/AGENTS.md"
copy_path "$pack_root/PORTING-NOTES.md" "$agent_pack_home/PORTING-NOTES.md"
copy_path "$pack_root/docs" "$agent_pack_home/docs"
copy_path "$pack_root/memory" "$agent_pack_home/memory"
copy_path "$pack_root/references" "$agent_pack_home/references"
copy_path "$pack_root/scripts" "$agent_pack_home/scripts"
copy_dir_children "$pack_root/scripts" "$agent_pack_home/scripts"
copy_path "$pack_root/.agents" "$agent_pack_home/.agents"
copy_path "$pack_root/.codex" "$agent_pack_home/.codex"
copy_path "$pack_root/skills" "$agent_pack_home/skills"
copy_path "$pack_root/custom-agents" "$agent_pack_home/custom-agents"
copy_path "$pack_root/hooks" "$agent_pack_home/hooks"

copy_dir_children "$skills_source" "$skills_home"
copy_dir_children "$agents_source" "$codex_home/agents"

mkdir -p "$agent_pack_home/hooks"
copy_dir_children "$hook_scripts_source" "$agent_pack_home/hooks"

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

if [[ -n "$obsidian_vault" ]]; then
  if ! declare -F codex_agent_pack_write_obsidian_config >/dev/null; then
    echo "[!!] cannot write Obsidian config: missing scripts/obsidian-config.sh" >&2
    exit 1
  fi
  codex_agent_pack_write_obsidian_config "$agent_pack_home/obsidian.env" "$obsidian_vault" "${obsidian_projects_folder:-Codex/Projects}"
  echo "[ok] obsidian config: $agent_pack_home/obsidian.env"
  obsidian_configured=1
elif [[ "$import_claude_obsidian" -eq 1 ]]; then
  echo "[--] Claude Obsidian config not found; Obsidian autologging not configured."
fi

if [[ "$install_hooks" -eq 1 ]]; then
  hooks_destination="$codex_home/hooks.json"
  if [[ -e "$hooks_destination" && "$force" -ne 1 ]]; then
    echo "[!!] $hooks_destination already exists. Re-run with --force to replace it, or merge .codex/global-hooks.json manually."
    exit 1
  fi
  copy_path "$global_hooks_source" "$hooks_destination"
fi

cat <<EOF

Codex agent pack installed.

Skills:        $skills_home
Custom agents: $codex_home/agents
Support copy:  $agent_pack_home
Hooks:         $(if [[ "$install_hooks" -eq 1 ]]; then echo "$codex_home/hooks.json"; else echo "not installed"; fi)
Obsidian:      $(if [[ "$obsidian_configured" -eq 1 ]]; then echo "$agent_pack_home/obsidian.env"; else echo "not configured"; fi)

Restart Codex or start a new session so it reloads global skills and agents.
EOF

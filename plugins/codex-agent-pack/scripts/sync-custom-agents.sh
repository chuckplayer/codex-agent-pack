#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/sync-custom-agents.sh [--force] [--hooks] [--source PATH] [--target PATH] [--codex-home PATH] [--support-home PATH]

Installs Codex custom agents from this pack into:
  ${CODEX_HOME:-$HOME/.codex}/agents

Use --hooks to also install global hooks.json and the hook support files needed
by those hooks. Use --force to replace existing installed files.
USAGE
}

force=0
install_hooks=0
source_dir=""
target_dir=""
codex_home="${CODEX_HOME:-$HOME/.codex}"
support_home=""

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
    copy_path "$hook_dir_source" "$support_home/hooks"
  fi

  if [[ -n "$scripts_source" ]]; then
    copy_path "$scripts_source" "$support_home/scripts"
  fi

  for file in AGENTS.md PORTING-NOTES.md LICENSE; do
    if [[ -f "$pack_root/$file" ]]; then
      copy_path "$pack_root/$file" "$support_home/$file"
    fi
  done
fi

cat <<EOF

Codex custom agents synced.

Source:        $source_dir
Custom agents: $target_dir
Hooks:         $(if [[ "$install_hooks" -eq 1 ]]; then echo "$codex_home/hooks.json"; else echo "not installed"; fi)
Support copy:  $(if [[ "$install_hooks" -eq 1 ]]; then echo "$support_home"; else echo "not updated"; fi)

Restart Codex or start a new session so it reloads custom agents.
EOF

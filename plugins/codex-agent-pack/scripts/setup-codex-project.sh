#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/setup-codex-project.sh [--target PATH] [--pack-root PATH] [--force] [--skip-skills] [--skip-agents]

Copies this Codex agent pack into a target repository. Use --force to replace
existing pack-managed files and directories.
USAGE
}

target="$(pwd)"
pack_root=""
force=0
skip_skills=0
skip_agents=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="${2:?Missing value for --target}"
      shift 2
      ;;
    --pack-root)
      pack_root="${2:?Missing value for --pack-root}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --skip-skills)
      skip_skills=1
      shift
      ;;
    --skip-agents)
      skip_agents=1
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

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -z "$pack_root" ]]; then
  pack="$(cd "$script_dir/.." && pwd -P)"
else
  pack="$(cd "$pack_root" && pwd -P)"
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

mkdir -p "$target"
case "$target" in
  /*)
    target_path="$(cd "$target" && pwd -P)"
    ;;
  *)
    target_path="$target"
    ;;
esac

copy_one() {
  local source="$1"
  local destination="$2"

  if [[ ! -e "$source" ]]; then
    echo "[skip] source missing: $source"
    return 0
  fi

  if [[ -e "$destination" && "$force" -ne 1 ]]; then
    echo "[--] exists: $destination"
    return 0
  fi

  mkdir -p "$(dirname -- "$destination")"
  if [[ -e "$destination" && "$force" -eq 1 ]]; then
    rm -rf -- "$destination"
  fi

  cp -R -- "$source" "$destination"
  echo "[ok] copied: $destination"
}

skills_source="$(first_existing_dir "$pack/.agents/skills" "$pack/skills" || true)"
agents_source="$(first_existing_dir "$pack/.codex/agents" "$pack/custom-agents" || true)"
project_hooks_source="$(first_existing_file "$pack/.codex/hooks.json" "$pack/hooks/hooks.json" || true)"
global_hooks_source="$(first_existing_file "$pack/.codex/global-hooks.json" "$pack/hooks/global-hooks.json" || true)"
hook_scripts_source="$(first_existing_dir "$pack/.codex/hooks" "$pack/hooks" || true)"

copy_one "$pack/AGENTS.md" "$target_path/AGENTS.md"
copy_one "$pack/docs/CONVENTIONS.md" "$target_path/docs/CONVENTIONS.md"
copy_one "$pack/docs/MEMORY-WRITING.md" "$target_path/docs/MEMORY-WRITING.md"

for name in architecture context decisions known-issues; do
  mkdir -p "$target_path/memory/$name"
done

if [[ "$skip_skills" -ne 1 ]]; then
  copy_one "$skills_source" "$target_path/.agents/skills"
fi

if [[ "$skip_agents" -ne 1 ]]; then
  copy_one "$agents_source" "$target_path/.codex/agents"
fi

copy_one "$project_hooks_source" "$target_path/.codex/hooks.json"
copy_one "$global_hooks_source" "$target_path/.codex/global-hooks.json"
copy_one "$hook_scripts_source" "$target_path/.codex/hooks"
copy_one "$pack/scripts" "$target_path/scripts"

echo
echo "Codex project setup complete."
echo "Target: $target_path"
echo "Next: start Codex from the target repo and run /skills to inspect available skills."

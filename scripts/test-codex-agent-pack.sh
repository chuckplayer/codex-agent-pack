#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/test-codex-agent-pack.sh [--pack-root PATH] [--strict]

Validates Codex skills, custom agents, hooks, and support scripts in this pack.
USAGE
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
pack_root="$(cd "$script_dir/.." && pwd -P)"
strict=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pack-root)
      pack_root="$(cd "${2:?Missing value for --pack-root}" && pwd -P)"
      shift 2
      ;;
    --strict)
      strict=1
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

failures_file="$(mktemp)"
warnings_file="$(mktemp)"
trap 'rm -f "$failures_file" "$warnings_file"' EXIT

add_failure() {
  printf '%s\n' "$*" >> "$failures_file"
}

add_warning() {
  printf '%s\n' "$*" >> "$warnings_file"
}

line_count() {
  wc -l < "$1" | tr -d '[:space:]'
}

field_exists() {
  local field="$1"
  local frontmatter="$2"
  printf '%s\n' "$frontmatter" | grep -Eq "^${field}[[:space:]]*:"
}

test_skill() {
  local file="$1"
  local skill_name
  skill_name="$(basename "$(dirname "$file")")"

  if ! head -n 1 "$file" | grep -qx -- '---'; then
    add_failure "$skill_name: missing YAML frontmatter"
    return
  fi

  local frontmatter
  frontmatter="$(awk 'NR == 1 { next } $0 == "---" { exit } { print }' "$file")"
  if [[ -z "$frontmatter" ]]; then
    add_failure "$skill_name: empty or unterminated YAML frontmatter"
    return
  fi

  for required in name description; do
    if ! field_exists "$required" "$frontmatter"; then
      add_failure "$skill_name: missing required frontmatter field '$required'"
    fi
  done

  while IFS= read -r field; do
    case "$field" in
      name|description) ;;
      *) add_failure "$skill_name: unsupported Codex skill frontmatter field '$field'" ;;
    esac
  done < <(printf '%s\n' "$frontmatter" | sed -nE 's/^([A-Za-z][A-Za-z0-9_-]*)[[:space:]]*:.*/\1/p')

  local declared
  declared="$(printf '%s\n' "$frontmatter" | awk -F: '/^name[[:space:]]*:/ { value=$2; sub(/^[ \t]+/, "", value); gsub(/^["'\'']|["'\'']$/, "", value); print value; exit }')"
  if [[ -n "$declared" && "$declared" != "$skill_name" ]]; then
    add_failure "$skill_name: declared name '$declared' does not match directory"
  fi

  local marker
  for marker in 'CLAUDE.md' '~/.claude' 'CLAUDE_PROJECT_DIR' 'isolation: "worktree"' 'scripts/setup-project.sh' 'scripts/check-readiness.sh' 'scripts/check-updates.sh' 'scripts/lint-agents.sh'; do
    if grep -Fq "$marker" "$file"; then
      add_warning "$skill_name: contains converted-platform marker '$marker'"
    fi
  done
}

test_agent() {
  local file="$1"
  local filename expected declared required
  filename="$(basename "$file")"
  expected="${filename%.toml}"

  for required in name description developer_instructions; do
    if ! grep -Eq "^${required}[[:space:]]*=" "$file"; then
      add_failure "$filename: missing required custom agent field '$required'"
    fi
  done

  declared="$(awk -F= '/^name[[:space:]]*=/ { value=$2; sub(/^[ \t]+/, "", value); gsub(/^"|"$/, "", value); print value; exit }' "$file")"
  if [[ -n "$declared" && "$declared" != "$expected" ]]; then
    add_failure "$filename: declared name '$declared' does not match filename '$expected'"
  fi
}

skill_root="$pack_root/.agents/skills"
agent_root="$pack_root/.codex/agents"

if [[ ! -d "$skill_root" ]]; then
  add_failure "Missing skill root: $skill_root"
else
  while IFS= read -r -d '' file; do
    test_skill "$file"
  done < <(find "$skill_root" -type f -name SKILL.md -print0)
fi

if [[ ! -d "$agent_root" ]]; then
  add_failure "Missing custom agent root: $agent_root"
else
  while IFS= read -r -d '' file; do
    test_agent "$file"
  done < <(find "$agent_root" -maxdepth 1 -type f -name '*.toml' -print0)
fi

for script in \
  install-codex-agent-pack.sh \
  setup-codex-project.sh \
  test-codex-agent-pack.sh \
  write-obsidian-note.sh; do
  if [[ ! -f "$pack_root/scripts/$script" ]]; then
    add_failure "Missing support script: scripts/$script"
  fi
done

for hook in hooks.json global-hooks.json hooks/codex-user-prompt-hook.sh hooks/codex-stop-hook.sh; do
  if [[ ! -f "$pack_root/.codex/$hook" ]]; then
    add_failure "Missing Codex hook asset: .codex/$hook"
  fi
done

echo "Codex Agent Pack validation"
echo "Pack: $pack_root"
echo

if [[ "$(line_count "$warnings_file")" -gt 0 ]]; then
  echo "Warnings:"
  sort "$warnings_file" | sed 's/^/  [warn] /'
  echo
fi

if [[ "$(line_count "$failures_file")" -gt 0 ]]; then
  echo "Failures:"
  sort "$failures_file" | sed 's/^/  [fail] /'
  exit 1
fi

if [[ "$strict" -eq 1 && "$(line_count "$warnings_file")" -gt 0 ]]; then
  echo "Strict mode treats warnings as failures."
  exit 1
fi

echo "PASS"

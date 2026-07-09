#!/usr/bin/env bash
set -uo pipefail

if [[ -z "${CODEX_OBSIDIAN_VAULT_PATH:-${OBSIDIAN_VAULT_PATH:-}}" ]]; then
  exit 0
fi

root="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$root" ]]; then
  root="$(pwd)"
fi
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"
if [[ -z "$script_dir" ]]; then
  script_dir="$(pwd)"
fi
project="$(basename "$root")"
branch="$(git -C "$root" branch --show-current 2>/dev/null || true)"
status="$(git -C "$root" status --short 2>/dev/null || true)"
commits="$(git -C "$root" log -5 --oneline 2>/dev/null || true)"
writer=""
writer_candidates=(
  "$script_dir/../scripts/write-obsidian-note.sh"
  "$script_dir/../../scripts/write-obsidian-note.sh"
)
if [[ -n "${CODEX_AGENT_PACK_HOME:-}" ]]; then
  writer_candidates+=("$CODEX_AGENT_PACK_HOME/scripts/write-obsidian-note.sh")
fi
if [[ -n "${CODEX_HOME:-}" ]]; then
  writer_candidates+=("$CODEX_HOME/agent-pack/scripts/write-obsidian-note.sh")
fi
writer_candidates+=(
  "$HOME/.codex/agent-pack/scripts/write-obsidian-note.sh"
)

for candidate in "${writer_candidates[@]}"; do
  if [[ -f "$candidate" ]]; then
    writer="$candidate"
    break
  fi
done

if [[ -z "$writer" ]]; then
  exit 0
fi

if [[ -z "$branch" ]]; then
  branch="unknown"
fi
if [[ -z "$status" ]]; then
  status="Clean working tree or status unavailable."
fi
if [[ -z "$commits" ]]; then
  commits="No recent commits available."
fi

body="$(cat <<BODY
Project: $project
Root: $root
Branch: $branch

Status:
$status

Recent commits:
$commits
BODY
)"

printf '%s\n' "$body" | bash "$writer" --mode capture --project "$project" --title "Codex session update - $project" >/dev/null 2>&1 || true
exit 0

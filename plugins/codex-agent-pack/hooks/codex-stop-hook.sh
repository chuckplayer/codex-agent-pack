#!/usr/bin/env bash
set -uo pipefail

if [[ -z "${CODEX_OBSIDIAN_VAULT_PATH:-${OBSIDIAN_VAULT_PATH:-}}" ]]; then
  exit 0
fi

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
project="$(basename "$root")"
branch="$(git -C "$root" branch --show-current 2>/dev/null || true)"
status="$(git -C "$root" status --short 2>/dev/null || true)"
commits="$(git -C "$root" log -5 --oneline 2>/dev/null || true)"
writer="$root/scripts/write-obsidian-note.sh"

if [[ ! -f "$writer" ]]; then
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

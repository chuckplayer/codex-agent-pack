#!/usr/bin/env bash
set -uo pipefail

payload="$(cat 2>/dev/null || true)"
timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cwd="$(pwd -P 2>/dev/null || pwd)"

if [[ -n "${CODEX_AGENT_PACK_JOURNAL_DIR:-}" ]]; then
  journal_root="$CODEX_AGENT_PACK_JOURNAL_DIR"
elif [[ -n "${CODEX_HOME:-}" ]]; then
  journal_root="$CODEX_HOME/agent-pack-journals"
else
  journal_root="$HOME/.codex/agent-pack-journals"
fi

mkdir -p "$journal_root" 2>/dev/null || exit 0
cwd_hash="$(printf '%s' "$cwd" | cksum | awk '{print $1}')"
session_id="${CODEX_SESSION_ID:-$(date -u +%Y%m%d)-$cwd_hash}"
journal="$journal_root/$session_id.log"

{
  printf '%s\n' '---'
  printf 'event: UserPromptSubmit\n'
  printf 'timestamp: %s\n' "$timestamp"
  printf 'cwd: %s\n' "$cwd"
  printf 'payload:\n'
  printf '%s\n' "$payload"
} >> "$journal" 2>/dev/null || true

exit 0

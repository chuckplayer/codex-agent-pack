#!/usr/bin/env bash

codex_agent_pack_expand_path() {
  local value="$1"
  case "$value" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s/%s\n' "$HOME" "${value#~/}"
      ;;
    *)
      printf '%s\n' "$value"
      ;;
  esac
}

codex_agent_pack_normalize_projects_folder() {
  local value="${1:-Codex/Projects}"
  value="${value//\\//}"
  value="${value#/}"
  value="${value%/}"
  if [[ -z "$value" ]]; then
    value="Codex/Projects"
  fi

  case "$value" in
    /*|..|../*|*/..|*/../*|*:*)
      return 1
      ;;
  esac

  printf '%s\n' "$value"
}

codex_agent_pack_write_obsidian_config() {
  local config_path="$1"
  local vault_path="$2"
  local projects_folder="${3:-Codex/Projects}"

  if [[ -z "$vault_path" ]]; then
    echo "Missing Obsidian vault path." >&2
    return 2
  fi

  local expanded_vault
  expanded_vault="$(codex_agent_pack_expand_path "$vault_path")"
  if [[ -d "$expanded_vault" ]]; then
    expanded_vault="$(cd "$expanded_vault" && pwd -P)"
  fi

  local safe_projects_folder
  if ! safe_projects_folder="$(codex_agent_pack_normalize_projects_folder "$projects_folder")"; then
    echo "Refusing unsafe Obsidian projects folder: $projects_folder" >&2
    return 2
  fi

  mkdir -p "$(dirname -- "$config_path")"
  {
    printf '# Codex Agent Pack Obsidian configuration\n'
    printf '# Written by the Codex Agent Pack installer.\n'
    printf 'CODEX_OBSIDIAN_VAULT_PATH=%s\n' "$expanded_vault"
    printf 'CODEX_OBSIDIAN_PROJECTS_FOLDER=%s\n' "$safe_projects_folder"
  } > "$config_path"
}

codex_agent_pack_default_obsidian_config_paths() {
  if [[ -n "${CODEX_AGENT_PACK_OBSIDIAN_CONFIG:-}" ]]; then
    printf '%s\n' "$CODEX_AGENT_PACK_OBSIDIAN_CONFIG"
  fi
  if [[ -n "${CODEX_AGENT_PACK_HOME:-}" ]]; then
    printf '%s\n' "$CODEX_AGENT_PACK_HOME/obsidian.env"
  fi
  if [[ -n "${CODEX_HOME:-}" ]]; then
    printf '%s\n' "$CODEX_HOME/agent-pack/obsidian.env"
  fi
  printf '%s\n' "$HOME/.codex/agent-pack/obsidian.env"
}

codex_agent_pack_apply_obsidian_config_file() {
  local config_path="$1"
  [[ -f "$config_path" ]] || return 1

  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    case "$line" in
      ""|\#*)
        continue
        ;;
      *=*)
        key="${line%%=*}"
        value="${line#*=}"
        value="${value%$'\r'}"
        case "$key" in
          CODEX_OBSIDIAN_VAULT_PATH)
            if [[ -z "${CODEX_OBSIDIAN_VAULT_PATH:-}" ]]; then
              export CODEX_OBSIDIAN_VAULT_PATH="$value"
            fi
            ;;
          OBSIDIAN_VAULT_PATH)
            if [[ -z "${OBSIDIAN_VAULT_PATH:-}" ]]; then
              export OBSIDIAN_VAULT_PATH="$value"
            fi
            ;;
          CODEX_OBSIDIAN_PROJECTS_FOLDER)
            if [[ -z "${CODEX_OBSIDIAN_PROJECTS_FOLDER:-}" ]]; then
              export CODEX_OBSIDIAN_PROJECTS_FOLDER="$value"
            fi
            ;;
          OBSIDIAN_PROJECTS_FOLDER)
            if [[ -z "${OBSIDIAN_PROJECTS_FOLDER:-}" ]]; then
              export OBSIDIAN_PROJECTS_FOLDER="$value"
            fi
            ;;
        esac
        ;;
    esac
  done < "$config_path"

  return 0
}

codex_agent_pack_load_obsidian_config() {
  local config_path
  for config_path in "$@"; do
    if codex_agent_pack_apply_obsidian_config_file "$config_path"; then
      return 0
    fi
  done

  while IFS= read -r config_path; do
    if codex_agent_pack_apply_obsidian_config_file "$config_path"; then
      return 0
    fi
  done < <(codex_agent_pack_default_obsidian_config_paths)

  return 1
}

codex_agent_pack_json_tool() {
  local candidate
  for candidate in python3 python node; do
    command -v "$candidate" >/dev/null 2>&1 || continue
    case "$candidate" in
      python*) "$candidate" -c 'import sys; sys.exit(0)' >/dev/null 2>&1 || continue ;;
      node) "$candidate" -e 'process.exit(0)' >/dev/null 2>&1 || continue ;;
    esac
    printf '%s\n' "$candidate"
    return 0
  done
  return 1
}

codex_agent_pack_read_claude_obsidian_config() {
  local key="$1"
  local settings_path="${2:-$HOME/.claude/settings.json}"
  [[ -f "$settings_path" ]] || return 1

  local json_tool
  json_tool="$(codex_agent_pack_json_tool)" || return 1

  if [[ "$json_tool" == "node" ]]; then
    node - "$settings_path" "$key" <<'JSEOF'
const fs = require('fs');
const [settingsPath, key] = process.argv.slice(2);
try {
  const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  const value = settings.env && settings.env[key];
  if (typeof value === 'string') process.stdout.write(value);
} catch {}
JSEOF
  else
    "$json_tool" - "$settings_path" "$key" <<'PYEOF'
import json
import sys

settings_path, key = sys.argv[1], sys.argv[2]
try:
    with open(settings_path, encoding="utf-8") as handle:
        settings = json.load(handle)
    value = settings.get("env", {}).get(key, "")
    if isinstance(value, str):
        sys.stdout.write(value)
except Exception:
    pass
PYEOF
  fi
}

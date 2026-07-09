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
smoke_tmp=""
trap 'rm -f "$failures_file" "$warnings_file"; if [[ -n "$smoke_tmp" ]]; then rm -rf "$smoke_tmp"; fi' EXIT

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
  build-plugin.sh \
  install-codex-plugin.sh \
  install-codex-agent-pack.sh \
  setup-codex-project.sh \
  sync-custom-agents.sh \
  test-codex-agent-pack.sh \
  obsidian-config.sh \
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

if [[ ! -f "$pack_root/README.md" ]]; then
  add_failure "Missing README.md"
fi

plugin_root="$pack_root/plugins/codex-agent-pack"
plugin_manifest="$plugin_root/.codex-plugin/plugin.json"
marketplace="$pack_root/.agents/plugins/marketplace.json"

if [[ ! -d "$plugin_root" ]]; then
  add_failure "Missing plugin package: plugins/codex-agent-pack. Run scripts/build-plugin.sh."
else
  for dir in skills custom-agents hooks scripts; do
    if [[ ! -d "$plugin_root/$dir" ]]; then
      add_failure "Plugin package missing directory: plugins/codex-agent-pack/$dir"
    fi
  done

  if [[ ! -f "$plugin_manifest" ]]; then
    add_failure "Plugin package missing manifest: plugins/codex-agent-pack/.codex-plugin/plugin.json"
  else
    for marker in \
      '"name": "codex-agent-pack"' \
      '"version":' \
      '"description":' \
      '"skills": "./skills/"' \
      '"displayName": "Codex Agent Pack"'; do
      if ! grep -Fq "$marker" "$plugin_manifest"; then
        add_failure "Plugin manifest missing marker: $marker"
      fi
    done

    if grep -Eq '"hooks"[[:space:]]*:' "$plugin_manifest"; then
      add_failure "Plugin manifest contains unsupported top-level hooks field"
    fi
  fi

  if [[ -d "$skill_root" && -d "$plugin_root/skills" ]]; then
    source_skill_count="$(find "$skill_root" -type f -name SKILL.md | wc -l | tr -d '[:space:]')"
    plugin_skill_count="$(find "$plugin_root/skills" -type f -name SKILL.md | wc -l | tr -d '[:space:]')"
    if [[ "$source_skill_count" != "$plugin_skill_count" ]]; then
      add_failure "Plugin skill count $plugin_skill_count does not match source skill count $source_skill_count"
    fi
  fi

  if [[ -d "$agent_root" && -d "$plugin_root/custom-agents" ]]; then
    source_agent_count="$(find "$agent_root" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d '[:space:]')"
    plugin_agent_count="$(find "$plugin_root/custom-agents" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d '[:space:]')"
    if [[ "$source_agent_count" != "$plugin_agent_count" ]]; then
      add_failure "Plugin custom agent count $plugin_agent_count does not match source custom agent count $source_agent_count"
    fi
  fi

  for asset in \
    README.md \
    scripts/install-codex-plugin.sh \
    scripts/setup-codex-project.sh \
    scripts/sync-custom-agents.sh \
    scripts/obsidian-config.sh \
    docs/INSTALL.md \
    hooks/global-hooks.json \
    hooks/hooks.json \
    hooks/codex-user-prompt-hook.sh \
    hooks/codex-stop-hook.sh; do
    if [[ ! -f "$plugin_root/$asset" ]]; then
      add_failure "Plugin package missing asset: plugins/codex-agent-pack/$asset"
    fi
  done

  if [[ -f "$plugin_root/hooks/hooks.json" ]]; then
    if grep -Fq '$root/.codex/hooks' "$plugin_root/hooks/hooks.json"; then
      add_failure "Plugin hooks config references project-local .codex hooks"
    fi
    if ! grep -Fq 'CODEX_AGENT_PACK_HOME' "$plugin_root/hooks/hooks.json"; then
      add_failure "Plugin hooks config does not reference support-copy hook location"
    fi
  fi
fi

if [[ -f "$pack_root/scripts/sync-custom-agents.sh" && -f "$pack_root/.codex/hooks/codex-stop-hook.sh" ]]; then
  smoke_tmp="$(mktemp -d)"
  mkdir -p "$smoke_tmp/codex/agent-pack/hooks" "$smoke_tmp/codex/agent-pack/scripts"

  mkdir -p "$smoke_tmp/vault"

  if ! bash "$pack_root/scripts/sync-custom-agents.sh" --hooks --codex-home "$smoke_tmp/codex" --obsidian-vault "$smoke_tmp/vault" --obsidian-projects-folder "Codex/Projects" >/dev/null 2>&1; then
    add_failure "Hook support smoke: sync-custom-agents.sh --hooks failed"
  else
    for asset in \
      hooks/codex-user-prompt-hook.sh \
      hooks/codex-stop-hook.sh \
      scripts/obsidian-config.sh \
      scripts/write-obsidian-note.sh; do
      if [[ ! -f "$smoke_tmp/codex/agent-pack/$asset" ]]; then
        add_failure "Hook support smoke missing asset: $asset"
      fi
    done

    if [[ ! -f "$smoke_tmp/codex/agent-pack/obsidian.env" ]]; then
      add_failure "Hook support smoke missing obsidian config: obsidian.env"
    elif ! grep -Fq 'CODEX_OBSIDIAN_VAULT_PATH=' "$smoke_tmp/codex/agent-pack/obsidian.env"; then
      add_failure "Hook support smoke obsidian config missing vault path"
    fi

    if ! (cd "$smoke_tmp" && CODEX_HOME="$smoke_tmp/codex" bash "$smoke_tmp/codex/agent-pack/hooks/codex-stop-hook.sh" >/dev/null 2>&1); then
      add_failure "Hook support smoke: codex-stop-hook.sh failed outside pack root"
    fi

    if ! find "$smoke_tmp/vault/Codex/captures" -type f -name '*.md' 2>/dev/null | grep -q .; then
      add_failure "Hook support smoke: codex-stop-hook.sh did not write Obsidian capture from config"
    fi
  fi
fi

if [[ ! -f "$marketplace" ]]; then
  add_failure "Missing marketplace file: .agents/plugins/marketplace.json"
else
  for marker in \
    '"name": "codex-agent-pack-local"' \
    '"path": "./plugins/codex-agent-pack"' \
    '"installation": "AVAILABLE"' \
    '"authentication": "ON_INSTALL"' \
    '"category": "Developer Tools"'; do
    if ! grep -Fq "$marker" "$marketplace"; then
      add_failure "Marketplace missing marker: $marker"
    fi
  done
fi

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

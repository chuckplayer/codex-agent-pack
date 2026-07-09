#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/build-plugin.sh [--pack-root PATH] [--version VERSION]

Builds the repo-local Codex plugin package at:
  plugins/codex-agent-pack

The source of truth remains the authoring layout:
  .agents/skills
  .codex/agents
  .codex/hooks
  scripts
USAGE
}

plugin_name="codex-agent-pack"
version="${CODEX_AGENT_PACK_VERSION:-0.1.0}"
pack_root=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pack-root)
      pack_root="${2:?Missing value for --pack-root}"
      shift 2
      ;;
    --version)
      version="${2:?Missing value for --version}"
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

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -z "$pack_root" ]]; then
  pack_root="."
  pack_root_abs="$(cd "$script_dir/.." && pwd -P)"
else
  pack_root="$(cd "$pack_root" && pwd -P)"
  pack_root_abs="$pack_root"
fi

require_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "Missing required directory: $path" >&2
    exit 1
  fi
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

copy_dir() {
  local source="$1"
  local destination="$2"
  require_dir "$source"
  mkdir -p "$destination"
  cp -R -- "$source"/. "$destination"/
}

copy_file() {
  local source="$1"
  local destination="$2"
  require_file "$source"
  mkdir -p "$(dirname -- "$destination")"
  cp -- "$source" "$destination"
}

plugins_root="$pack_root/plugins"
mkdir -p "$plugins_root"
plugins_root_abs="$(cd "$plugins_root" && pwd -P)"
plugin_root="$plugins_root/$plugin_name"
plugin_root_abs="$plugins_root_abs/$plugin_name"

case "$plugin_root_abs" in
  "$pack_root_abs"/plugins/"$plugin_name") ;;
  *)
    echo "Refusing to rebuild unexpected plugin path: $plugin_root_abs" >&2
    exit 1
    ;;
esac

if [[ -e "$plugin_root" ]]; then
  rm -rf -- "$plugin_root"
fi

mkdir -p \
  "$plugin_root/.codex-plugin" \
  "$plugin_root/skills" \
  "$plugin_root/custom-agents" \
  "$plugin_root/hooks" \
  "$plugin_root/scripts"

copy_dir "$pack_root/.agents/skills" "$plugin_root/skills"
copy_dir "$pack_root/.codex/agents" "$plugin_root/custom-agents"
copy_dir "$pack_root/.codex/hooks" "$plugin_root/hooks"
copy_file "$pack_root/.codex/hooks.json" "$plugin_root/hooks/hooks.json"
copy_file "$pack_root/.codex/global-hooks.json" "$plugin_root/hooks/global-hooks.json"
copy_dir "$pack_root/scripts" "$plugin_root/scripts"
copy_dir "$pack_root/docs" "$plugin_root/docs"
copy_dir "$pack_root/references" "$plugin_root/references"
copy_dir "$pack_root/memory" "$plugin_root/memory"
copy_file "$pack_root/README.md" "$plugin_root/README.md"
copy_file "$pack_root/AGENTS.md" "$plugin_root/AGENTS.md"
copy_file "$pack_root/PORTING-NOTES.md" "$plugin_root/PORTING-NOTES.md"
copy_file "$pack_root/LICENSE" "$plugin_root/LICENSE"

cat > "$plugin_root/.codex-plugin/plugin.json" <<EOF
{
  "name": "codex-agent-pack",
  "version": "$version",
  "description": "Codex-native skills, custom-agent sync scripts, hooks, and project setup workflows.",
  "author": {
    "name": "Chuck Player",
    "url": "https://github.com/chuckplayer"
  },
  "homepage": "https://github.com/chuckplayer/codex-agent-pack",
  "repository": "https://github.com/chuckplayer/codex-agent-pack",
  "license": "MIT",
  "keywords": [
    "codex",
    "skills",
    "agents",
    "workflow"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "Codex Agent Pack",
    "shortDescription": "Reusable Codex skills plus scripts for custom agents and project setup.",
    "longDescription": "A Codex-native workflow pack with skills, custom-agent TOML files, lifecycle hook assets, and setup scripts. Custom agents and global hooks are installed with the bundled sync script after plugin install.",
    "developerName": "Chuck Player",
    "category": "Developer Tools",
    "capabilities": [
      "Skills",
      "Scripts",
      "Project setup"
    ],
    "defaultPrompt": [
      "Run system-check for this Codex pack.",
      "Sync the Codex Agent Pack custom agents.",
      "Set up this repo for the Codex Agent Pack."
    ]
  }
}
EOF

mkdir -p "$pack_root/.agents/plugins"
cat > "$pack_root/.agents/plugins/marketplace.json" <<'EOF'
{
  "name": "codex-agent-pack-local",
  "interface": {
    "displayName": "Codex Agent Pack Local"
  },
  "plugins": [
    {
      "name": "codex-agent-pack",
      "source": {
        "source": "local",
        "path": "./plugins/codex-agent-pack"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Developer Tools"
    }
  ]
}
EOF

cat <<EOF
Built Codex plugin package.

Plugin:      $plugin_root_abs
Marketplace: $pack_root_abs/.agents/plugins/marketplace.json
Version:     $version
EOF

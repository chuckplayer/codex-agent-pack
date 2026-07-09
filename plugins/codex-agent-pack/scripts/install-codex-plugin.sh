#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/install-codex-plugin.sh [options]

Builds and installs the repo-local Codex Agent Pack plugin, then syncs custom
agents and optional global hooks.

Options:
  --hooks              Sync global hooks.json and hook support files.
  --force              Replace existing synced custom agents/hooks.
  --cachebuster        Add a UTC cachebuster suffix to the generated plugin version.
  --cachebuster-token  Use a specific cachebuster token with --cachebuster.
  --version VERSION    Base plugin version to build. Default: 0.1.0.
  --skip-build         Do not rebuild plugins/codex-agent-pack.
  --skip-marketplace   Do not run "codex plugin marketplace add".
  --skip-plugin        Do not run "codex plugin add".
  --skip-sync          Do not sync custom agents or hooks.
  --codex-bin PATH     Codex CLI executable. Default: codex.
  --codex-home PATH    Codex home for synced custom agents/hooks.
  --obsidian-vault PATH
                       Configure Obsidian autologging for installed hooks.
  --obsidian-projects-folder PATH
                       Vault-relative project folder. Default: Codex/Projects.
  --import-claude-obsidian
                       Import vault and project folder from ~/.claude/settings.json.
  --dry-run            Print commands without running them.

Common install:
  bash scripts/install-codex-plugin.sh --hooks

Local update/reinstall:
  bash scripts/install-codex-plugin.sh --hooks --cachebuster
USAGE
}

plugin_name="codex-agent-pack"
version="${CODEX_AGENT_PACK_VERSION:-0.1.0}"
codex_bin="${CODEX_BIN:-codex}"
codex_home="${CODEX_HOME:-$HOME/.codex}"
install_hooks=0
force=0
cachebuster=0
cachebuster_token=""
skip_build=0
skip_marketplace=0
skip_plugin=0
skip_sync=0
dry_run=0
obsidian_vault=""
obsidian_projects_folder=""
import_claude_obsidian=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hooks)
      install_hooks=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    --cachebuster)
      cachebuster=1
      shift
      ;;
    --cachebuster-token)
      cachebuster=1
      cachebuster_token="${2:?Missing value for --cachebuster-token}"
      shift 2
      ;;
    --version)
      version="${2:?Missing value for --version}"
      shift 2
      ;;
    --skip-build)
      skip_build=1
      shift
      ;;
    --skip-marketplace)
      skip_marketplace=1
      shift
      ;;
    --skip-plugin)
      skip_plugin=1
      shift
      ;;
    --skip-sync)
      skip_sync=1
      shift
      ;;
    --codex-bin)
      codex_bin="${2:?Missing value for --codex-bin}"
      shift 2
      ;;
    --codex-home)
      codex_home="${2:?Missing value for --codex-home}"
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
    --dry-run)
      dry_run=1
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
pack_root="$(cd "$script_dir/.." && pwd -P)"
plugin_root="$pack_root/plugins/$plugin_name"
marketplace_file="$pack_root/.agents/plugins/marketplace.json"
marketplace_name="codex-agent-pack-local"

quote_arg() {
  local value="$1"
  printf "'%s'" "$(printf '%s' "$value" | sed "s/'/'\\\\''/g")"
}

print_command() {
  local arg
  printf '+'
  for arg in "$@"; do
    printf ' '
    quote_arg "$arg"
  done
  printf '\n'
}

run_cmd() {
  if [[ "$dry_run" -eq 1 ]]; then
    print_command "$@"
  else
    "$@"
  fi
}

run_in_pack() {
  if [[ "$dry_run" -eq 1 ]]; then
    printf '+ cd '
    quote_arg "$pack_root"
    printf ' &&'
    local arg
    for arg in "$@"; do
      printf ' '
      quote_arg "$arg"
    done
    printf '\n'
  else
    (cd "$pack_root" && "$@")
  fi
}

codex_path_arg() {
  local path="$1"
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*)
      if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$path"
        return 0
      fi
      ;;
  esac
  printf '%s\n' "$path"
}

if [[ ! -d "$pack_root/.agents/skills" || ! -d "$pack_root/.codex/agents" ]]; then
  echo "This installer must be run from the source checkout, not from the generated plugin package." >&2
  echo "For an installed plugin package, run scripts/sync-custom-agents.sh instead." >&2
  exit 1
fi

if [[ "$dry_run" -ne 1 && ( "$skip_marketplace" -ne 1 || "$skip_plugin" -ne 1 ) ]]; then
  if ! command -v "$codex_bin" >/dev/null 2>&1; then
    echo "Codex CLI not found: $codex_bin" >&2
    echo "Install Codex or pass --codex-bin <path>. Use --skip-marketplace --skip-plugin to only build and sync." >&2
    exit 1
  fi
fi

build_version="$version"
if [[ "$cachebuster" -eq 1 ]]; then
  if [[ -z "$cachebuster_token" ]]; then
    cachebuster_token="local-$(date -u +%Y%m%d-%H%M%S)"
  fi
  build_version="${version%%+*}+codex.$cachebuster_token"
fi

if [[ "$skip_build" -ne 1 ]]; then
  run_in_pack bash scripts/build-plugin.sh --version "$build_version"
fi

if [[ -f "$marketplace_file" ]]; then
  detected_marketplace_name="$(sed -nE 's/^[[:space:]]*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$marketplace_file" | head -n 1)"
  if [[ -n "$detected_marketplace_name" ]]; then
    marketplace_name="$detected_marketplace_name"
  fi
fi

if [[ ! -f "$marketplace_file" ]]; then
  echo "Missing marketplace file: $marketplace_file" >&2
  echo "Run scripts/build-plugin.sh first, or omit --skip-build." >&2
  exit 1
fi

if [[ ! -f "$plugin_root/.codex-plugin/plugin.json" ]]; then
  echo "Missing plugin manifest: $plugin_root/.codex-plugin/plugin.json" >&2
  echo "Run scripts/build-plugin.sh first, or omit --skip-build." >&2
  exit 1
fi

marketplace_root_for_codex="$(codex_path_arg "$pack_root")"

if [[ "$skip_marketplace" -ne 1 ]]; then
  run_cmd "$codex_bin" plugin marketplace add "$marketplace_root_for_codex"
fi

if [[ "$skip_plugin" -ne 1 ]]; then
  run_cmd "$codex_bin" plugin add "$plugin_name@$marketplace_name"
fi

if [[ "$skip_sync" -ne 1 ]]; then
  sync_args=(bash "$plugin_root/scripts/sync-custom-agents.sh" --codex-home "$codex_home")
  if [[ "$install_hooks" -eq 1 ]]; then
    sync_args+=(--hooks)
  fi
  if [[ "$force" -eq 1 ]]; then
    sync_args+=(--force)
  fi
  if [[ -n "$obsidian_vault" ]]; then
    sync_args+=(--obsidian-vault "$obsidian_vault")
  fi
  if [[ -n "$obsidian_projects_folder" ]]; then
    sync_args+=(--obsidian-projects-folder "$obsidian_projects_folder")
  fi
  if [[ "$import_claude_obsidian" -eq 1 ]]; then
    sync_args+=(--import-claude-obsidian)
  fi
  run_cmd "${sync_args[@]}"
fi

cat <<EOF

Codex plugin install flow complete.

Plugin package: $plugin_root
Marketplace:    $marketplace_file
Plugin ref:     $plugin_name@$marketplace_name
Version:        $build_version
Custom agents:  $(if [[ "$skip_sync" -ne 1 ]]; then echo "$codex_home/agents"; else echo "not synced"; fi)
Hooks:          $(if [[ "$install_hooks" -eq 1 && "$skip_sync" -ne 1 ]]; then echo "$codex_home/hooks.json"; else echo "not installed"; fi)
Obsidian:       $(if [[ "$skip_sync" -ne 1 && ( -n "$obsidian_vault" || "$import_claude_obsidian" -eq 1 ) ]]; then echo "$codex_home/agent-pack/obsidian.env"; else echo "not configured"; fi)

Start a new Codex session so plugin skills and custom agents reload.
EOF

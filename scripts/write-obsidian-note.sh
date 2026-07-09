#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/write-obsidian-note.sh [--mode capture|recap] [--vault-path PATH] [--projects-folder PATH] [--project NAME] [--title TEXT] [--body TEXT] [--date YYYY-MM-DD]

Writes a Codex capture or recap note into an Obsidian vault. If --body is not
provided, stdin is used when piped.
USAGE
}

mode="capture"
vault_path="${CODEX_OBSIDIAN_VAULT_PATH:-${OBSIDIAN_VAULT_PATH:-}}"
projects_folder="${CODEX_OBSIDIAN_PROJECTS_FOLDER:-Codex/Projects}"
project="$(basename "$PWD")"
title=""
body=""
date_value="$(date +%Y-%m-%d)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:?Missing value for --mode}"
      shift 2
      ;;
    --vault-path)
      vault_path="${2:?Missing value for --vault-path}"
      shift 2
      ;;
    --projects-folder)
      projects_folder="${2:?Missing value for --projects-folder}"
      shift 2
      ;;
    --project)
      project="${2:?Missing value for --project}"
      shift 2
      ;;
    --title)
      title="${2:?Missing value for --title}"
      shift 2
      ;;
    --body)
      body="${2:?Missing value for --body}"
      shift 2
      ;;
    --date)
      date_value="${2:?Missing value for --date}"
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

case "$mode" in
  capture|recap) ;;
  *)
    echo "--mode must be capture or recap" >&2
    exit 2
    ;;
esac

if [[ -z "$body" && ! -t 0 ]]; then
  body="$(cat)"
fi

if [[ -z "$vault_path" ]]; then
  echo "Set CODEX_OBSIDIAN_VAULT_PATH, OBSIDIAN_VAULT_PATH, or pass --vault-path." >&2
  exit 1
fi

vault="$(cd "$vault_path" && pwd -P)"
safe_projects_folder="${projects_folder#/}"
safe_projects_folder="${safe_projects_folder%/}"
if [[ -z "$safe_projects_folder" ]]; then
  safe_projects_folder="Codex/Projects"
fi
case "$safe_projects_folder" in
  /*|..|../*|*/..|*/../*)
    echo "Refusing unsafe projects folder: $projects_folder" >&2
    exit 1
    ;;
esac

slug="$(printf '%s' "$project" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
if [[ -z "$slug" ]]; then
  slug="project"
fi
slug="${slug:0:60}"
slug="${slug%-}"

timestamp="$(date +%Y-%m-%dT%H:%M)"
time_value="$(date +%H:%M)"
stamp="$(date +%Y-%m-%d-%H%M)"

if [[ -z "$title" ]]; then
  if [[ -n "$body" ]]; then
    title="$(printf '%s\n' "$body" | sed -n '1p')"
  else
    title="$mode $stamp"
  fi
fi

if [[ -z "$body" ]]; then
  body="$title"
fi

write_note() {
  local path="$1"
  mkdir -p "$(dirname -- "$path")"
  cat > "$path"
}

if [[ "$mode" == "capture" ]]; then
  relative="Codex/captures/$stamp.md"
  path="$vault/$relative"
  {
    printf -- '---\n'
    printf 'type: codex/capture\n'
    printf 'project: %s\n' "$project"
    printf 'date: %s\n' "$date_value"
    printf 'captured_at: %s\n' "$timestamp"
    printf 'tags: [codex, capture]\n'
    printf -- '---\n\n'
    printf '# %s\n\n%s\n' "$title" "$body"
  } | write_note "$path"
else
  relative="$safe_projects_folder/$slug/recaps/$date_value.md"
  path="$vault/$relative"
  {
    printf -- '---\n'
    printf 'type: codex/recap\n'
    printf 'project: %s\n' "$project"
    printf 'date: %s\n' "$date_value"
    printf 'tags: [codex, recap, project/%s]\n' "$slug"
    printf -- '---\n\n'
    printf '# Recap - %s - %s\n\n%s\n' "$project" "$date_value" "$body"
  } | write_note "$path"
fi

vault_relative="${relative%.md}"
daily="$vault/$safe_projects_folder/$slug/daily/$date_value.md"
daily_line="- $time_value $mode [[$vault_relative]]"

mkdir -p "$(dirname -- "$daily")"
if [[ ! -f "$daily" ]]; then
  printf '# %s\n\n%s\n' "$date_value" "$daily_line" > "$daily"
else
  printf '\n%s\n' "$daily_line" >> "$daily"
fi

echo "Mode: $mode"
echo "Path: $path"
echo "Daily: $daily"
echo "VaultRelative: $vault_relative"

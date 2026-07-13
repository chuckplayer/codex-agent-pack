# Codex Agent Pack

Codex Agent Pack is a Codex-native workflow pack for software projects. It
packages reusable skills, custom agent definitions, lifecycle hook assets, and
setup scripts that were ported from a Claude agent pack into Codex surfaces.

The recommended distribution path is a hybrid Codex plugin install:

- The plugin exposes reusable Codex skills.
- A bundled sync script installs Codex custom agents and optional global hooks.
- Project setup scripts can copy the pack into individual repositories when a
  repo-local setup is useful.

## Contents

- `27` Codex skills under `.agents/skills`.
- `18` Codex custom agents under `.codex/agents`.
- Project-local hook config under `.codex/hooks.json`.
- Optional user-level hook config under `.codex/global-hooks.json`.
- Shell scripts under `scripts/` for macOS, Linux, and Windows with Git Bash.
- A generated plugin package under `plugins/codex-agent-pack`.
- A repo-local plugin marketplace at `.agents/plugins/marketplace.json`.
- Team conventions and memory folders under `docs/` and `memory/`.

## Requirements

- Codex CLI available as `codex`.
- Bash.
  - macOS and Linux include a suitable shell in normal developer setups.
  - Windows users should run these commands from Git Bash, or invoke Git Bash
    from PowerShell.
- Git, if you want to clone or update the pack from GitHub.

The scripts use POSIX shell tooling and avoid PowerShell-specific entrypoints.

## Quick Install

From a source checkout of this repository:

```bash
bash scripts/install-codex-plugin.sh --hooks
```

This performs the full hybrid install:

1. Builds `plugins/codex-agent-pack` from the source layout.
2. Registers this checkout as a local Codex plugin marketplace.
3. Installs `codex-agent-pack@codex-agent-pack-local`.
4. Syncs custom agents into `${CODEX_HOME:-$HOME/.codex}/agents`.
5. With `--hooks`, installs global hooks into
   `${CODEX_HOME:-$HOME/.codex}/hooks.json` and copies hook support files.

Start a new Codex session after installing so the plugin skills and custom
agents are reloaded.

To configure the Obsidian note scripts using an existing Claude Code Obsidian
setup:

```bash
bash scripts/install-codex-plugin.sh --import-claude-obsidian
```

Or configure the Codex pack directly:

```bash
bash scripts/install-codex-plugin.sh \
  --obsidian-vault "/absolute/path/to/your/vault" \
  --obsidian-projects-folder "Codex/Projects"
```

## Preview Install Commands

Use `--dry-run` to inspect what the installer will execute without changing
Codex plugin state or syncing files:

```bash
bash scripts/install-codex-plugin.sh --hooks --dry-run
```

The dry run is useful before the first install, or before running an update with
a cachebuster.

## Updating an Existing Install

After pulling changes or editing skills, custom agents, hooks, docs, or scripts,
run:

```bash
bash scripts/install-codex-plugin.sh --hooks --cachebuster
```

`--cachebuster` rebuilds the plugin with a version like:

```text
0.1.0+codex.local-YYYYMMDD-HHMMSS
```

That gives Codex a changed local plugin version during reinstall while keeping
the base package version stable.

Use a specific cachebuster token when a repeatable local version is useful:

```bash
bash scripts/install-codex-plugin.sh --hooks --cachebuster-token local-test-1
```

Start a new Codex session after reinstalling.

## Install Script Options

The main installer is `scripts/install-codex-plugin.sh`.

Common options:

- `--hooks`: sync global hooks and hook support files.
- `--force`: replace existing synced custom agents or hooks.
- `--cachebuster`: append a UTC local cachebuster to the plugin version.
- `--cachebuster-token <token>`: choose the cachebuster token.
- `--version <version>`: set the base plugin version. Default is `0.1.0`.
- `--dry-run`: print commands without running them.
- `--codex-bin <path>`: use a specific Codex CLI executable.
- `--codex-home <path>`: sync agents and hooks to a non-default Codex home.
- `--obsidian-vault <path>`: configure Obsidian note scripts and skills.
- `--obsidian-projects-folder <path>`: set the vault-relative project folder
  for Obsidian notes. Default is `Codex/Projects`.
- `--import-claude-obsidian`: import `OBSIDIAN_VAULT_PATH` and
  `OBSIDIAN_PROJECTS_FOLDER` from `~/.claude/settings.json`.
- `--skip-marketplace`: skip `codex plugin marketplace add`.
- `--skip-plugin`: skip `codex plugin add`.
- `--skip-sync`: skip custom agent and hook sync.
- `--skip-build`: reuse the existing `plugins/codex-agent-pack` package.

Examples:

```bash
# Full install with hooks
bash scripts/install-codex-plugin.sh --hooks

# Reinstall after local edits
bash scripts/install-codex-plugin.sh --hooks --cachebuster

# Build and sync only, without touching Codex plugin configuration
bash scripts/install-codex-plugin.sh --hooks --skip-marketplace --skip-plugin

# Use a non-default Codex home
bash scripts/install-codex-plugin.sh --hooks --codex-home "$HOME/.codex-dev"

# Configure Obsidian note scripts from Claude Code settings
bash scripts/install-codex-plugin.sh --import-claude-obsidian
```

## Script-Only Install

If you do not want to use Codex plugin marketplaces, install the files directly
for the current user:

```bash
bash scripts/install-codex-agent-pack.sh --hooks
```

This installs:

- skills to `$HOME/.agents/skills`;
- custom agents to `${CODEX_HOME:-$HOME/.codex}/agents`;
- a support copy to `${CODEX_HOME:-$HOME/.codex}/agent-pack`;
- optional global hooks to `${CODEX_HOME:-$HOME/.codex}/hooks.json`.

Use `--force` only when replacing existing installed files is intentional:

```bash
bash scripts/install-codex-agent-pack.sh --hooks --force
```

## Project Setup

Use project setup when you want the pack copied into a specific repository
instead of only installed globally:

```bash
bash scripts/setup-codex-project.sh --target /path/to/project
```

This copies:

- `AGENTS.md`;
- selected docs;
- memory folder structure;
- `.agents/skills`;
- `.codex/agents`;
- `.codex/hooks.json`;
- `.codex/global-hooks.json`;
- `.codex/hooks`;
- `scripts`.

Use `--force` only when replacing pack-managed files in the target repository is
intentional:

```bash
bash scripts/setup-codex-project.sh --target /path/to/project --force
```

Useful variants:

```bash
# Copy docs, hooks, agents, and scripts, but not skills
bash scripts/setup-codex-project.sh --target /path/to/project --skip-skills

# Copy docs, hooks, skills, and scripts, but not custom agents
bash scripts/setup-codex-project.sh --target /path/to/project --skip-agents
```

## Using the Pack

After install, start a new Codex session from the repository you want to work
in. The skills are intended to be used by name or by natural-language requests.

Common workflows:

- `implement`: inspect context, plan, edit, test, review, and hand off a code
  change.
- `plan`: prepare a structured implementation plan before editing.
- `review-pr`: review a pull request or local changes.
- `scaffold`: create a new project or feature structure.
- `debug`: investigate a failing behavior or test.
- `devops`: route GitHub or Azure DevOps issue, PR, and work-item requests.
- `devops-github`: handle one-off GitHub PR and issue operations via `gh`.
- `devops-azure`: handle one-off Azure DevOps work-item and PR operations via
  `az`.
- `hotfix`: make a focused urgent fix.
- `repo-map`: map an unfamiliar repository.
- `onboard`: build initial repository context.
- `system-check`: validate that this pack is installed correctly.
- `sync-custom-agents`: install or update custom agents and hooks after plugin
  changes.

The orchestration skills may call custom agents such as `tech-lead`,
`code-reviewer`, `security-reviewer`, `test-engineer`, `frontend-engineer`,
`python-engineer`, `csharp-engineer`, and `database-engineer` when those roles
fit the task.

## Hooks

Hooks are optional. With `--hooks`, the installer writes:

```text
${CODEX_HOME:-$HOME/.codex}/hooks.json
```

The hook script records prompt context for local journaling. It is best-effort
and exits successfully when journaling is unavailable.

## Obsidian

Obsidian note capture uses these environment variables:

- `CODEX_OBSIDIAN_VAULT_PATH`: preferred vault path.
- `OBSIDIAN_VAULT_PATH`: fallback vault path.
- `CODEX_OBSIDIAN_PROJECTS_FOLDER`: preferred vault-relative project folder.
- `OBSIDIAN_PROJECTS_FOLDER`: fallback vault-relative project folder.

The installer can also write these values to:

```text
${CODEX_HOME:-$HOME/.codex}/agent-pack/obsidian.env
```

The explicit Obsidian skills and scripts load that file before checking the
environment. If neither the config file nor the environment provides a vault
path, Obsidian-specific writes are skipped.

## DevOps Target Configuration

The DevOps skills can persist GitHub and Azure DevOps target variables in a
Codex Agent Pack env file:

```text
${CODEX_AGENT_PACK_ENV_FILE:-${CODEX_HOME:-$HOME/.codex}/agent-pack/env.sh}
```

Use the helper script after confirming values:

```bash
bash scripts/set-env.sh GITHUB_ORG=<org> GITHUB_REPOS=<repo-a,repo-b>
bash scripts/set-env.sh AZURE_DEVOPS_ORG=<org> AZURE_DEVOPS_PROJECTS=<ProjectA,ProjectB>
```

The DevOps skills load that file before checking the current environment.

## Development Workflow

The source of truth is:

- `.agents/skills`
- `.codex/agents`
- `.codex/hooks`
- `scripts`
- `docs`
- `references`
- `memory`

After changing source files, rebuild and validate:

```bash
bash scripts/build-plugin.sh
bash scripts/test-codex-agent-pack.sh --strict
```

Then reinstall for local testing:

```bash
bash scripts/install-codex-plugin.sh --hooks --cachebuster
```

## Validation

Run strict validation before committing or publishing:

```bash
bash scripts/test-codex-agent-pack.sh --strict
```

The validator checks:

- skill frontmatter;
- custom agent TOML required fields;
- required scripts and hook assets;
- generated plugin package shape;
- plugin manifest markers;
- marketplace markers;
- source/package skill and custom-agent counts.

For a full package refresh plus validation:

```bash
bash scripts/build-plugin.sh
bash scripts/test-codex-agent-pack.sh --strict
```

## Troubleshooting

Codex CLI not found:

```bash
bash scripts/install-codex-plugin.sh --hooks --codex-bin /path/to/codex
```

Inspect commands without changing Codex state:

```bash
bash scripts/install-codex-plugin.sh --hooks --dry-run
```

Only rebuild the plugin package:

```bash
bash scripts/build-plugin.sh
```

Only resync custom agents and hooks:

```bash
bash scripts/sync-custom-agents.sh --hooks
```

Replace existing synced agents or hooks:

```bash
bash scripts/sync-custom-agents.sh --hooks --force
```

If a plugin update does not appear in Codex, reinstall with a cachebuster and
start a new session:

```bash
bash scripts/install-codex-plugin.sh --hooks --cachebuster
```

## Publishing

Before publishing:

```bash
bash scripts/build-plugin.sh
bash scripts/test-codex-agent-pack.sh --strict
git status --short
```

Commit both the source files and the generated `plugins/codex-agent-pack`
package so users can install from the repo-local marketplace immediately after
clone.

## License

See `LICENSE`.

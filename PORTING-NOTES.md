# Porting Notes

Updated: 2026-07-09
Source: `C:\Users\playechu\source\repos\claude-agent-pack`

The pack has been converted to Codex-native surfaces:

- 27 reusable skills under `.agents/skills`, including a sync helper for
  installing custom agents from the plugin package.
- 18 custom Codex agents under `.codex/agents`.
- Project lifecycle hooks under `.codex/hooks.json` and `.codex/hooks`.
- A generated Codex plugin package under `plugins/codex-agent-pack`.
- A repo-local marketplace entry under `.agents/plugins/marketplace.json`.
- Cross-platform support scripts with `.sh` entrypoints for macOS/Linux and
  Windows with Git Bash.

## Conversion Choices

- Claude-style callable agents were replaced with Codex custom agents.
- Workflows no longer assume isolated worktrees. Skills use the current checkout
  unless the user or Codex surface explicitly creates a separate worktree.
- Setup, validation, and Obsidian writes use deterministic support scripts.
- Obsidian integration is explicit through skills and scripts. It uses
  `CODEX_OBSIDIAN_VAULT_PATH`, falls back to `OBSIDIAN_VAULT_PATH`, and writes
  under `Codex/` paths by default.
- DevOps skill target persistence uses
  `${CODEX_AGENT_PACK_ENV_FILE:-${CODEX_HOME:-$HOME/.codex}/agent-pack/env.sh}`
  via `scripts/set-env.sh` instead of Claude settings injection.
- Hook scripts are best-effort and exit successfully when prompt journaling is
  unavailable. Lifecycle hooks do not write Obsidian notes.
- The plugin package carries skills and support files. Custom agents and global
  hooks are installed with `scripts/sync-custom-agents.sh` because those surfaces
  are not represented as supported plugin manifest fields.
- `scripts/install-codex-plugin.sh` codifies the full hybrid flow: build,
  marketplace registration, plugin install, custom-agent sync, and optional
  global hooks.

## Validation

Run strict validation before publishing changes:

```bash
bash scripts/build-plugin.sh
bash scripts/test-codex-agent-pack.sh --strict
```

Rebuild the plugin whenever skills, custom agents, hooks, docs, or support
scripts change.

## Global Install

Install for the current user with:

```bash
bash scripts/install-codex-plugin.sh --hooks
```

For script-only install without the plugin marketplace, use:

```bash
bash scripts/install-codex-agent-pack.sh --hooks
```

Use `--force` only when replacing existing installed files is intentional.

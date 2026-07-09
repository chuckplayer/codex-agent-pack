# Porting Notes

Updated: 2026-07-09
Source: `C:\Users\playechu\source\repos\claude-agent-pack`

The pack has been converted to Codex-native surfaces:

- 23 reusable skills under `.agents/skills`.
- 18 custom Codex agents under `.codex/agents`.
- Project lifecycle hooks under `.codex/hooks.json` and `.codex/hooks`.
- Cross-platform support scripts with `.sh` entrypoints for macOS/Linux and
  Windows with Git Bash.

## Conversion Choices

- Claude-style callable agents were replaced with Codex custom agents.
- Workflows no longer assume isolated worktrees. Skills use the current checkout
  unless the user or Codex surface explicitly creates a separate worktree.
- Setup, validation, and Obsidian writes use deterministic support scripts.
- Obsidian integration uses `CODEX_OBSIDIAN_VAULT_PATH`, falling back to
  `OBSIDIAN_VAULT_PATH`, and writes under `Codex/` paths by default.
- Hook scripts are best-effort and exit successfully when journaling or vault
  configuration is unavailable.

## Validation

Run strict validation before publishing changes:

```bash
bash scripts/test-codex-agent-pack.sh --strict
```

## Global Install

Install for the current user with:

```bash
bash scripts/install-codex-agent-pack.sh
```

Use `--hooks` to install global Codex hooks. Use `--force` only when replacing
existing installed files is intentional.

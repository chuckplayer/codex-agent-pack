# Install

Use Bash on macOS, Linux, or Windows with Git Bash.

## Plugin Install

From the source checkout:

```bash
bash scripts/install-codex-plugin.sh --hooks
```

This runs the hybrid install flow:

1. Build `plugins/codex-agent-pack`.
2. Register this checkout as a local Codex plugin marketplace.
3. Install `codex-agent-pack@codex-agent-pack-local`.
4. Sync custom agents into `${CODEX_HOME:-$HOME/.codex}/agents`.
5. With `--hooks`, install global hooks into `${CODEX_HOME:-$HOME/.codex}/hooks.json`.

Start a new Codex session after installing.

To enable Obsidian autologging from an existing Claude Code setup:

```bash
bash scripts/install-codex-plugin.sh --hooks --import-claude-obsidian
```

To configure it directly:

```bash
bash scripts/install-codex-plugin.sh --hooks \
  --obsidian-vault "/absolute/path/to/your/vault" \
  --obsidian-projects-folder "Codex/Projects"
```

## Local Updates

After changing skills, agents, hooks, docs, or scripts:

```bash
bash scripts/install-codex-plugin.sh --hooks --cachebuster
```

`--cachebuster` rebuilds the plugin version as
`<base-version>+codex.local-<utc-timestamp>` so Codex sees the local package as
updated during reinstall.

Use `--dry-run` to inspect the exact commands:

```bash
bash scripts/install-codex-plugin.sh --hooks --cachebuster --dry-run
```

## Script-Only Install

If you do not want to use the plugin marketplace path, install the files
directly for the current user:

```bash
bash scripts/install-codex-agent-pack.sh --hooks
```

Use `--force` only when replacing existing installed files is intentional.

Obsidian autologging can be configured the same way:

```bash
bash scripts/install-codex-agent-pack.sh --hooks --import-claude-obsidian
```

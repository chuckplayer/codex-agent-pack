---
name: sync-custom-agents
description: "Install or update Codex custom agents and optional global hooks from the Codex Agent Pack after installing, updating, or building the plugin package. Use when custom agents, hook scripts, or user-level hooks need to be available across projects."
---

# Sync Custom Agents

Use this after installing or updating the Codex Agent Pack plugin, because the plugin manifest exposes skills but custom agents and user-level hooks still need an explicit sync step.

For a source checkout, prefer the full install flow:

```bash
bash scripts/install-codex-plugin.sh --hooks
```

Run from the pack root or from the installed plugin package root:

```bash
bash scripts/sync-custom-agents.sh
```

Install global hooks and the hook support files as well:

```bash
bash scripts/sync-custom-agents.sh --hooks
```

Use `--force` only when replacing installed custom agents or hooks is intentional.

Default destinations:
- custom agents: `${CODEX_HOME:-$HOME/.codex}/agents`
- hooks config: `${CODEX_HOME:-$HOME/.codex}/hooks.json`
- hook support copy: `${CODEX_HOME:-$HOME/.codex}/agent-pack`

For a non-default Codex home, pass `--codex-home <path>`. For a custom source or target, pass `--source <path>` or `--target <path>`.

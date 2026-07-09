---
name: setup-project
description: "Install this Codex agent pack into a target repository by copying AGENTS.md, docs, memory folders, .agents/skills, .codex/agents, hooks, and support scripts. Use when initializing a repo for these Codex workflows."
---

# Setup Project

Use this skill to copy the pack into a target repository. Confirm the target directory if the user did not make it explicit.

If running from a global install, the pack root is:

```bash
"${CODEX_AGENT_PACK_HOME:-${CODEX_HOME:-$HOME/.codex}/agent-pack}"
```

Run with Bash on macOS, Linux, or Windows with Git Bash:

```bash
bash <pack-root>/scripts/setup-codex-project.sh --target <target-repo>
```

Use `--force` only when the user wants existing pack-managed files replaced. Existing project code is not touched.

The setup copies:
- `AGENTS.md`,
- `docs/CONVENTIONS.md` and `docs/MEMORY-WRITING.md`,
- `memory/architecture`, `memory/context`, `memory/decisions`, and `memory/known-issues`,
- `.agents/skills`,
- `.codex/agents`,
- `.codex/hooks.json` and `.codex/hooks`,
- `scripts`.

After setup, recommend:
- run `system-check` in the target repo,
- customize `docs/CONVENTIONS.md`,
- run `repo-map` or `onboard` if the repo is unfamiliar,
- commit the scaffolding if the user wants it versioned.

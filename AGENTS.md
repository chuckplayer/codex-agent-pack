# Codex Agent Pack

This repository contains a Codex-native port of the agent and skill workflows
from `C:\Users\playechu\source\repos\claude-agent-pack`.

## Layout

- `.agents/skills/<skill-name>/SKILL.md` contains reusable Codex skills.
- `.codex/agents/*.toml` contains Codex custom agents used by orchestration
  skills such as `implement`, `plan`, `review-pr`, and `scaffold`.
- `.codex/hooks.json` and `.codex/hooks/` contain project-local best-effort
  lifecycle hooks for prompt journaling and optional Obsidian session capture.
- `.codex/global-hooks.json` is the user-level hooks file copied by the
  installer when global hooks are requested.
- `scripts/*.sh` are the supported entrypoints for macOS, Linux, and Windows
  with Git Bash.
- `docs/CONVENTIONS.md` contains project conventions.
- `memory/` contains team-shared durable context.

## Operating Rules

- Keep skill frontmatter limited to `name` and `description`.
- Put durable repository guidance here in `AGENTS.md`, not in every skill.
- Prefer repo-local conventions, scripts, and tests over generic patterns.
- Read active `memory/**/*.md` files when they may affect the task. Skip files
  marked archived or superseded unless historical context is required.
- Use Codex custom agents explicitly when they add value; subagents inherit the
  current sandbox and approval policy.
- Do not commit, push, rebase, delete branches, or write outside the workspace
  unless the user asked for that action or approved it.
- Preserve unrelated user changes in the working tree.

## Validation

Run one of these from the pack root:

```bash
bash scripts/test-codex-agent-pack.sh --strict
```

The validator checks skills, custom agents, hooks, and shell support scripts.

## Global Install

Use Bash on macOS, Linux, or Windows with Git Bash:

```bash
bash scripts/install-codex-agent-pack.sh
```

Add `--hooks` to install global lifecycle hooks into
`${CODEX_HOME:-$HOME/.codex}/hooks.json`. Use `--force` only when replacing an
existing installed pack or hooks file is intentional.

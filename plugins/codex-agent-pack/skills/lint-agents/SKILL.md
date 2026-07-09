---
name: lint-agents
description: "Validate this Codex agent pack's skills, custom agents, hooks, and support scripts. Use before committing pack changes, after editing .agents/skills or .codex/agents, or when checking whether a converted skill is Codex-ready."
---

# Lint Codex Agent Pack

Run the pack validator from the repository root with Bash on macOS, Linux, or Windows with Git Bash:

```bash
bash scripts/test-codex-agent-pack.sh --strict
```

Report warnings and failures exactly enough for the user to fix the file. Treat any remaining converted-platform marker as a failed gate in strict mode.

The validator checks:
- skill frontmatter contains only `name` and `description`,
- skill names match their directory names,
- custom agent TOML files contain required Codex fields,
- `.sh` support scripts exist,
- hook assets exist under `.codex/hooks`,
- converted skills no longer point to old platform-specific scripts or state.

After fixing an issue, rerun the same command and report the final PASS or FAIL.

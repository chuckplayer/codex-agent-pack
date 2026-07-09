---
name: system-check
description: "Verify that a repository or pack checkout has the expected Codex skill, custom agent, hook, memory, docs, and script structure. Use before starting work, after pulling updates, or when pack behavior seems wrong."
---

# System Check

Run the validator from the pack root or from a repository that has the pack files copied in. Use Bash on macOS, Linux, or Windows with Git Bash.

```bash
bash scripts/test-codex-agent-pack.sh
```

Use strict mode when this is a commit or release gate:

```bash
bash scripts/test-codex-agent-pack.sh --strict
```

If validation fails, group issues by remediation:
- missing pack files: run `setup-project`,
- invalid skill frontmatter: edit the named `SKILL.md`,
- invalid custom agent TOML: edit the named `.codex/agents/*.toml`,
- missing scripts or hooks: restore the pack-managed files,
- converted-platform markers: rewrite the affected skill to use Codex surfaces.

Report the final PASS or FAIL and the exact command used.

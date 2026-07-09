---
name: obsidian-recap
description: "Write a Codex project or session recap to Obsidian with summary, changed files, validation, decisions, and follow-up items."
---

# Obsidian Recap

Use this skill after meaningful work, debugging, review, or planning.

Build a concise body with:
- what changed or was learned,
- important files or commands,
- validation results,
- decisions made,
- follow-up tasks.

Run with Bash on macOS, Linux, or Windows with Git Bash:

```bash
printf '%s\n' "<recap body>" | bash scripts/write-obsidian-note.sh --mode recap --project "<project>" --title "<title>"
```

The recap is written under `Codex/Projects/<project>/recaps/<date>.md` unless `CODEX_OBSIDIAN_PROJECTS_FOLDER` or `OBSIDIAN_PROJECTS_FOLDER` changes the project root. The project daily index is updated automatically.

If the vault is not configured, skip the write and show the recap text to the user.

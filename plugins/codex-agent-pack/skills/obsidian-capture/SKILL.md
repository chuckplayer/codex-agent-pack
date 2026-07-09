---
name: obsidian-capture
description: "Write a concise Codex capture note to an Obsidian vault for a decision, shipped change, debugging result, or important project context."
---

# Obsidian Capture

Use this skill to create a short searchable note.

Run with Bash on macOS, Linux, or Windows with Git Bash:

```bash
printf '%s\n' "<body>" | bash scripts/write-obsidian-note.sh --mode capture --project "<project>" --title "<title>"
```

The scripts use `CODEX_OBSIDIAN_VAULT_PATH`, then `OBSIDIAN_VAULT_PATH`. They update both `Codex/captures/<timestamp>.md` and the project daily index.

Capture format:
- title: one line,
- body: 3 to 8 bullets or a short paragraph,
- include file paths, command results, commit SHA, or decision owner when useful,
- avoid full transcripts.

If no vault path is configured, say that capture was skipped and include the note body in the response.

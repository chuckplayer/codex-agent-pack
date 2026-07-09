---
name: obsidian-daily
description: "Create or update a daily Codex project note in Obsidian using configured vault and project-folder environment variables."
---

# Obsidian Daily

Use this for a daily project note or index entry.

Resolve the vault from the Codex Agent Pack `obsidian.env` config when available, then `CODEX_OBSIDIAN_VAULT_PATH`, then `OBSIDIAN_VAULT_PATH`. Resolve the project folder with `CODEX_OBSIDIAN_PROJECTS_FOLDER`, then `OBSIDIAN_PROJECTS_FOLDER`, defaulting to `Codex/Projects`.

For capture or recap entries, prefer:
- `obsidian-capture` for short notes,
- `obsidian-recap` for session summaries.

For a direct daily note edit, write only inside:

```text
<vault>/<projects-folder>/<project-slug>/daily/<yyyy-mm-dd>.md
```

Use a lowercase slug derived from the project name. Include:
- date heading,
- brief agenda or summary,
- links to captures or recaps,
- open follow-ups.

Do not write outside the configured vault.

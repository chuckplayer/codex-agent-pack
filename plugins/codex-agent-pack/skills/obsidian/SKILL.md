---
name: obsidian
description: "Use Codex Obsidian workflows for captures, recaps, daily notes, briefs, and vault search when CODEX_OBSIDIAN_VAULT_PATH or OBSIDIAN_VAULT_PATH is configured."
---

# Obsidian

Use this as the router for Obsidian-backed project memory.

Vault resolution:
- prefer `CODEX_OBSIDIAN_VAULT_PATH`,
- fall back to `OBSIDIAN_VAULT_PATH`,
- prefer `CODEX_OBSIDIAN_PROJECTS_FOLDER`,
- default project notes to `Codex/Projects`.

Choose the narrowest skill:
- `obsidian-capture` for a short note about a decision, implementation, or event,
- `obsidian-recap` for a project/session recap,
- `obsidian-daily` for a daily project note,
- `obsidian-search` for finding existing notes,
- `obsidian-brief` for a read-only brief from existing notes.

Do not invent a vault path. If the vault is not configured, ask the user for the path or skip Obsidian logging.

---
name: obsidian-search
description: "Search configured Codex Obsidian notes for prior decisions, recaps, captures, conventions, and project context before answering or editing."
---

# Obsidian Search

Use this skill when prior project memory may exist in Obsidian.

Resolve the vault from Codex Agent Pack `obsidian.env` when available, then `CODEX_OBSIDIAN_VAULT_PATH`, then `OBSIDIAN_VAULT_PATH`. If neither is set, report that Obsidian search is unavailable and continue with repository memory.

Search likely locations:
- `Codex/captures`,
- `Codex/Projects/<project-slug>`,
- the folder from `CODEX_OBSIDIAN_PROJECTS_FOLDER` or `OBSIDIAN_PROJECTS_FOLDER` when set.

Prefer exact searches for:
- feature names,
- file paths,
- error text,
- decision titles,
- ticket or PR numbers.

Summarize results with note paths and dates. Do not treat Obsidian notes as more authoritative than current repository files.

---
name: obsidian-brief
description: "Create a read-only brief from configured Codex Obsidian notes for a project, topic, decision area, or recent session history."
---

# Obsidian Brief

Use this skill to synthesize existing notes without writing new ones.

1. Resolve the vault from Codex Agent Pack `obsidian.env` when available, then `CODEX_OBSIDIAN_VAULT_PATH`, then `OBSIDIAN_VAULT_PATH`.
2. Search `Codex/captures`, `Codex/Projects/<project-slug>`, and the configured projects folder.
3. Read only notes relevant to the requested project, topic, date, or decision.
4. Produce a brief with:
   - current context,
   - decisions and rationale,
   - active risks,
   - follow-ups,
   - note paths used.

If the vault is unavailable, say so and fall back to repository `memory/` files.

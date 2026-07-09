---
name: conventions
description: "Create or update docs/CONVENTIONS.md by reading actual repository patterns and interviewing the user about ambiguous team standards."
---

# Conventions

Use this skill to document how the team wants the repository to be maintained.

1. Read existing `docs/CONVENTIONS.md` if present.
2. Read active memory files for decisions that should affect conventions.
3. Inspect representative code across layers to identify actual conventions: naming, architecture, error handling, testing, frontend patterns, logging, auth, data access, and deployment.
4. Ask one focused question at a time for ambiguous or inconsistent areas.
5. Write or update only `docs/CONVENTIONS.md` unless the user asks for more.
6. Preserve accurate user-written content. Update only sections that are missing, stale, or contradicted by confirmed team preference.
7. Mark aspirational conventions explicitly when existing code does not yet comply.

After editing, summarize what changed and recommend memory entries for significant architectural decisions discovered during the interview.

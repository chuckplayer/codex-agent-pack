---
name: memory-query
description: "Search active project memory files for a topic, decision, constraint, known issue, pattern, or historical rationale and return cited matches."
---

# Memory Query

Use this skill to answer a specific memory question.

1. If `memory/` is missing, report that no project memory is available.
2. Search `memory/**/*.md`.
3. Prefer active files. Skip archived or superseded files for current guidance, but mention them when they explain history and point to their replacement when present.
4. Match on topic names, file paths, modules, decisions, rationale, constraints, known issues, and workarounds.
5. Return each relevant memory entry with:
   - file path,
   - status and type when present,
   - a short quote or paraphrase,
   - one-sentence interpretation.

If active files conflict, surface the conflict instead of choosing silently. If no active memory matches, say so and recommend recording the decision if it exists outside the repo.

---
name: refactor
description: "Perform behavior-preserving code restructuring, simplification, extraction, or cleanup with focused validation and review."
---

# Refactor

Use this skill only when behavior should not change.

1. Identify the current behavior from tests, callers, docs, and nearby code.
2. Define the refactor boundary and state what must remain unchanged.
3. Use `tech-lead` for cross-module refactors and `devils-advocate` when the refactor might hide a behavior change.
4. Edit in small steps, preserving public contracts unless the user explicitly asked to change them.
5. Run existing tests before and after when practical, or run the narrowest validation that covers the touched surface.
6. Use `code-reviewer` and `smell-reviewer` for non-trivial refactors.
7. Report any behavior you could not verify.

Do not mix feature work into a refactor unless the user approves the scope expansion.

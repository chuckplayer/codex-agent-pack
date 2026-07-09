---
name: smell
description: "Identify maintainability, complexity, duplication, naming, responsibility, and design-smell issues in a code area without making changes by default."
---

# Smell Review

Use this skill for a design-quality pass.

1. Read AGENTS.md, docs/CONVENTIONS.md, relevant memory, and the target code.
2. Use `smell-reviewer` when available for an independent pass.
3. Focus on issues that create real maintenance cost or bug risk.
4. Provide findings with file and line references, impact, and the smallest cleanup.
5. Separate quick wins from larger refactors.

Do not edit files unless the user asks for cleanup implementation.

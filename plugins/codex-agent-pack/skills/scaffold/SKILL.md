---
name: scaffold
description: "Create a new vertical slice, module, service, feature skeleton, or project structure using Codex conventions and custom implementation agents."
---

# Scaffold

Use this skill when the user wants a new feature or component skeleton, not a full implementation.

1. Read AGENTS.md, docs/CONVENTIONS.md, relevant memory, and nearby examples.
2. Ask only for blocking product or naming details. Otherwise infer from existing patterns.
3. Use `tech-lead` for broad scaffolds and `api-designer` for new public API surfaces.
4. Create the smallest useful vertical slice: entrypoint, types, wiring, tests or fixtures, and documentation only when the repo convention requires it.
5. Use domain agents when useful: `frontend-engineer`, `csharp-engineer`, `python-engineer`, `mcp-engineer`, `database-engineer`, or `infrastructure-engineer`.
6. Run focused format, lint, typecheck, or test commands.
7. Use `code-reviewer` or `smell-reviewer` when the scaffold establishes a pattern others will copy.

Keep placeholder code minimal and explicit. Avoid speculative abstractions and unused extension points.

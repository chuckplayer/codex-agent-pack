---
name: plan
description: "Create a concrete implementation or migration plan before editing code, especially for ambiguous, multi-file, risky, or architecture-affecting work."
---

# Plan

Use this skill to produce a plan, not to implement.

1. Read AGENTS.md, docs/CONVENTIONS.md, relevant memory, and the code paths involved.
2. Start `tech-lead` for broad decomposition when custom agents are available.
3. Start `devils-advocate` if the plan changes architecture, dependencies, API shape, deployment, data model, or security boundaries.
4. Start `api-designer` for public or cross-service API changes.
5. Return a plan with:
   - assumptions,
   - affected files or modules,
   - implementation steps,
   - validation commands,
   - review agents to use,
   - risks and open questions.

Stop after the plan unless the user asked you to proceed with implementation.

---
name: interview-me
description: "Interview the user one question at a time to shape a vague idea into a decision, design brief, implementation plan, or next action."
---

# Interview Me

Use this skill when the user has an idea that is not ready for planning or implementation.

1. Ask one orienting question: what kind of work is this, such as feature, architecture, refactor, process, or research?
2. For code-related work, quietly inspect relevant repo context before asking detailed questions.
3. Ask one question at a time, in dependency order:
   - goal,
   - constraints,
   - approach,
   - success criteria,
   - risks,
   - implementation details.
4. For each question, briefly explain why it matters and offer a concrete default when useful.
5. Stop when the user signals readiness or the major branches are resolved.
6. If useful, write a design brief only after confirming the path with the user.
7. Hand off to `plan` when more decomposition is needed, or `implement` when the work is ready.

Do not over-interview. If the direction is clear, summarize decisions and move to the next requested action.

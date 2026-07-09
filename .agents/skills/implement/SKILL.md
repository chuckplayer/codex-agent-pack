---
name: implement
description: "Run an end-to-end Codex implementation workflow for a feature, fix, or behavior change: inspect context, plan, optionally use custom agents, edit code, test, review, and prepare handoff."
---

# Implement

Use this workflow for implementation work that needs more than a direct edit.

## Workflow

1. Inspect repo state: `git status`, current branch, AGENTS.md, docs/CONVENTIONS.md, relevant memory, package/project files, and nearby tests.
2. If the task is broad, start the `tech-lead` custom agent for a plan. If the plan introduces a new pattern, dependency, migration, or risky design choice, start `devils-advocate`.
3. If APIs change, start `api-designer` before editing.
4. Choose implementation agents by surface when useful:
   - C# or .NET: `csharp-engineer`
   - Python: `python-engineer`
   - frontend TypeScript, Vue, React, or CSS: `frontend-engineer`
   - MCP servers or tools: `mcp-engineer`
   - infrastructure or CI: `infrastructure-engineer`
   - database schema, migrations, SQL, or persistence: `database-engineer`
5. Edit in the current checkout unless the user explicitly asks for separate worktrees or the Codex surface creates them for the task.
6. Run focused validation. For TypeScript or Vue changes, use `ts-linter` or run the equivalent local scripts before review.
7. Start review agents when the change warrants it:
   - always use `code-reviewer` for non-trivial code changes,
   - use `security-reviewer` for auth, secrets, external input, data access, or PII,
   - use `performance-reviewer` for queries, hot paths, rendering, caching, or loops over large data,
   - use `smell-reviewer` for meaningful application logic changes.
8. If reviewers find missing coverage, start `test-engineer` or add the tests directly.
9. Use `merge-reviewer` for final readiness before commit, PR, or handoff.
10. Use `git-engineer` only when the user wants commit, push, branch, or PR help.

## Rules

- Do not commit, push, rebase, or delete branches unless the user requested it.
- Do not revert unrelated user changes.
- State skipped agents and why when a step is not relevant.
- Keep the final response focused on changed files, validation, and remaining risks.
- If Obsidian logging is configured, use `obsidian-capture` for a concise shipped-work note.

---
name: review-pr
description: "Review a pull request, local branch, or working tree diff using Codex review conventions and optional custom reviewer agents."
---

# Review PR

Take a code-review stance. Findings lead the response.

1. Determine the review target: PR, branch diff, or current working tree.
2. Inspect git status, diff, changed files, nearby tests, AGENTS.md, and relevant memory.
3. Use reviewer agents when available:
   - `code-reviewer` for correctness and regression risk,
   - `security-reviewer` for auth, data, secrets, external input, or permissions,
   - `performance-reviewer` for hot paths, queries, rendering, caching, or large data,
   - `smell-reviewer` for maintainability risks.
4. Run only read-oriented checks unless the user asked for fixes.
5. Report findings first, ordered by severity, with file and line references.
6. Add open questions only when they affect correctness or merge readiness.
7. If no issues are found, say that clearly and mention any unrun tests or residual risk.

Do not edit files during a review unless the user explicitly asks you to address the findings.

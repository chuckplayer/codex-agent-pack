---
name: onboard
description: "Generate a read-only orientation for a codebase by reading README files, AGENTS.md, conventions, memory, repo maps, and key source entry points."
---

# Onboard

Produce a structured orientation for a repository. Do not edit files.

1. Read, when present:
   - `README.md`,
   - `AGENTS.md`,
   - `docs/CONVENTIONS.md`,
   - active `memory/**/*.md` files,
   - `memory/architecture/repo-map.md`.
2. If the repo map has a `Verified-at-commit` stamp, compare it with current `HEAD` using `git diff --name-only <sha>..HEAD`. Use a current map as the structure backbone. If it is stale, say so and inspect changed areas directly.
3. Explore the codebase with fast file search. Identify top-level directories, solution or package files, app entry points, tests, configuration, data layer, frontend structure, and deployment files.
4. Summarize actual patterns, not aspirations.
5. Return:
   - what the project does,
   - architecture overview,
   - key entry points,
   - representative data or request flow,
   - where to find major concerns,
   - conventions and standards,
   - known gotchas,
   - good first tasks,
   - gaps or stale docs.

If important docs are missing, recommend `setup-project`, `conventions`, or `repo-map`; do not create them during onboarding.

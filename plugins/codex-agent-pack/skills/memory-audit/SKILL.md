---
name: memory-audit
description: "Review project memory files for stale, superseded, contradictory, or missing context; update statuses without deleting historical notes."
---

# Memory Audit

Audit the repository `memory/` directory.

1. If `memory/` is missing, report that and recommend `setup-project`.
2. Read active `memory/**/*.md` files. Skip files marked `status: archived` or `status: superseded` unless needed to resolve history.
3. Compare memory claims against the current codebase and docs.
4. For stale files:
   - set status to `archived` when the context no longer applies,
   - set status to `superseded` and fill `Superseded-by` when a newer decision replaced it.
5. Never delete memory files.
6. Check `memory/architecture/repo-map.md` drift by comparing `Verified-at-commit` to `HEAD`. Recommend `repo-map refresh` when needed.
7. Ask the user about major unrecorded decisions only when you see a likely gap.

Report files reviewed, files changed, stale repo-map status, contradictions, and recommended follow-up entries.

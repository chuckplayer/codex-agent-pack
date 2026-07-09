---
name: hotfix
description: "Apply a small, urgent, targeted fix when the root cause is known or strongly suspected, while minimizing blast radius and validating the affected behavior."
---

# Hotfix

Use this skill for narrow fixes, not broad redesign.

1. Confirm the failing behavior and the smallest code path involved.
2. Inspect branch and dirty state. Do not overwrite unrelated changes.
3. Make the minimal edit that fixes the issue.
4. Add or update a regression test when practical.
5. Run the narrowest relevant validation command.
6. Use `code-reviewer` for non-trivial fixes. Use `security-reviewer` if the fix touches auth, secrets, data access, or external input.
7. Use `merge-reviewer` before handoff if the hotfix will be committed or shipped.

Report the cause, fix, validation, and any follow-up work that should happen outside the hotfix.

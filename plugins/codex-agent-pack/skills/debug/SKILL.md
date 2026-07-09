---
name: debug
description: "Diagnose a bug, test failure, runtime error, flaky behavior, or production-like issue by gathering evidence before changing code."
---

# Debug

Use this skill when the cause is unknown.

1. Reproduce or localize the failure from logs, tests, commands, stack traces, and recent changes.
2. Inspect the relevant code and call paths before proposing a fix.
3. Form a short hypothesis list and test the highest-signal hypothesis first.
4. Add temporary diagnostics only when needed, and remove them before final handoff.
5. Once the cause is known, either apply a focused fix or switch to `hotfix` for a narrow patch.
6. Add a regression test when the bug is reproducible.
7. Run validation that covers the failure mode.

Report root cause separately from symptoms. If the issue cannot be reproduced, state what was checked and what evidence is missing.

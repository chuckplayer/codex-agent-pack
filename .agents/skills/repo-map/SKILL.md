---
name: repo-map
description: "Generate, refresh, or verify a durable directory-level repository map at memory/architecture/repo-map.md, stamped with the commit it was verified against."
---

# Repo Map

Maintain `memory/architecture/repo-map.md` as a compact structural index.

If `memory/` does not exist, report that and recommend `setup-project`.

## Modes

Default to `refresh` when the map exists, otherwise `generate`. Use `verify` when the user only asks whether the map is stale.

### Generate

1. Capture `git rev-parse --short HEAD`.
2. Enumerate meaningful directories, respecting ignores where possible.
3. Skip dependency, build, cache, and output directories such as `.git`, `node_modules`, `bin`, `obj`, `dist`, `target`, `.venv`, and `venv`.
4. For each meaningful directory, write a one-line purpose and 1 to 3 entry-point files.
5. Stamp `Verified-at-commit` and `Last-updated`.

### Refresh

1. Read `Verified-at-commit`.
2. Run `git diff --name-only <sha>..HEAD -- . ':(exclude)memory/architecture/repo-map.md'`.
3. Re-describe only directories that changed, were added, or were removed.
4. If the stamped commit is unreachable, regenerate and note why.
5. Update `Verified-at-commit` and `Last-updated`.

### Verify

1. Read `Verified-at-commit`.
2. Compare changed paths since that commit.
3. Report up to date or list drifted directories. Do not edit files.

## Format

Use `docs/MEMORY-WRITING.md` conventions. Include:

```text
**Date:** YYYY-MM-DD
**Type:** pattern
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** n/a
**Last-updated:** YYYY-MM-DD
**Verified-at-commit:** <short-sha>
```

Keep the body terse: one `## <dir>/` heading per meaningful directory, one purpose line, and a short entry-point list. Do not turn the map into a per-file manifest.

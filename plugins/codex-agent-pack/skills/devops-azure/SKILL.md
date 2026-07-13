---
name: devops-azure
description: "Read and create Azure DevOps work items and PRs via the az CLI devops extension for org/projects configured in AZURE_DEVOPS_ORG/AZURE_DEVOPS_PROJECTS. Use for one-off Azure Boards/Repos operations outside the code pipeline: viewing or creating work items, viewing PRs, commenting, updating state, or linking work items to PRs/commits. Do NOT use for GitHub PRs/issues. Do NOT use for full code review or implementation work; use review-pr or implement instead."
---

# Azure DevOps

Read and write Azure DevOps work items and PRs by shelling out to the `az` CLI
with the `azure-devops` extension. This skill handles first-time setup,
operation-aware targeting, runtime field-schema discovery, and safe writes for
the org and projects configured through environment variables or the Codex Agent
Pack env file.

## 1. Verify Setup

Check, in order:

1. `az` CLI installed: run `az --version`. If missing, stop and direct the user
   to install it from <https://learn.microsoft.com/cli/azure/install-azure-cli>.
2. `azure-devops` extension installed: run
   `az extension show --name azure-devops`. If missing, ask before installing it
   with `az extension add --name azure-devops`.
3. Authenticated: run `az account show`. If not logged in, walk the user
   through `az login` interactively. Do not ask the user to paste a PAT into
   chat.
4. Environment loaded: check `AZURE_DEVOPS_ORG` and
   `AZURE_DEVOPS_PROJECTS`.

Before checking the environment, load the Codex Agent Pack env file if it
exists:

```bash
env_file="${CODEX_AGENT_PACK_ENV_FILE:-${CODEX_HOME:-$HOME/.codex}/agent-pack/env.sh}"
if [ -f "$env_file" ]; then
  . "$env_file"
fi
```

`AZURE_DEVOPS_ORG` is a single organization name. `AZURE_DEVOPS_PROJECTS` is a
comma-delimited list, for example `AZURE_DEVOPS_PROJECTS=ReFac,AmLINK-Teams`.
If either value is unset, ask the user for the org and project or projects they
want to work with. Do not hardcode an org or project name into this skill.

Report each check's result clearly before proceeding.

After org/project targeting is resolved, optionally set Azure DevOps CLI
defaults for convenience:

```bash
az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>
```

Do not set defaults before targeting is confirmed.

## 1a. Persisting or Changing Azure DevOps Targets

Use `scripts/set-env.sh` to persist DevOps target variables for future Codex
sessions. It writes a shell-loadable env file at:

```text
${CODEX_AGENT_PACK_ENV_FILE:-${CODEX_HOME:-$HOME/.codex}/agent-pack/env.sh}
```

After confirming a new or changed value with the user, ask whether to persist
it. If yes:

```bash
bash scripts/set-env.sh AZURE_DEVOPS_ORG=<org> AZURE_DEVOPS_PROJECTS=<ProjectA,ProjectB>
```

Never hand-edit Codex config files or write shell-profile export lines to
persist these values. Use `scripts/set-env.sh` so the write is consistent across
macOS, Linux, and Windows with Git Bash.

A session-only value can be exported in the current shell or bypassed by passing
`--org` and `--project` explicitly for the current command.

## 2. Classify the Operation Before Resolving a Project

Azure DevOps work item IDs and PR IDs are unique org-wide, not per-project.
Split every request into one of two paths:

- ID-scoped reads: the user gives a specific work item or PR number, such as
  "read item 602810" or "show PR 41". Resolve the org only and skip project
  resolution. Do not validate the item's project against
  `AZURE_DEVOPS_PROJECTS`.
- Project-scoped operations: WIQL queries, `pr list`, creating a work item or
  PR, updating state, commenting, or linking. Resolve both org and project
  before running any command.

## 3. Resolve the Org

`AZURE_DEVOPS_ORG` is a single value. If unset, ask the user for it. Do not
guess or hardcode a default. The org is sufficient for ID-scoped reads.

## 4. Resolve the Target Project

Required for project-scoped operations only:

1. Parse `AZURE_DEVOPS_PROJECTS` into a list.
2. If the user names a project explicitly, it must match one of the configured
   entries case-insensitively. If it does not match, ask the user to correct it
   or add it to `AZURE_DEVOPS_PROJECTS`. Never silently substitute another
   configured project.
3. If no project is named and only one is configured, use it, but state the
   resolved org/project before running anything. Example: "Using
   `AMWINSGST/ReFac`, configured via `AZURE_DEVOPS_PROJECTS`."
4. If no project is named and multiple are configured, ask the user to
   disambiguate before running any `az boards` or `az repos` command.

## 5. Discover the Project Field Schema

Azure DevOps work item types, area paths, and iteration paths vary by project.
Before creating or updating a work item for the first time in a project this
session, query live project data:

```bash
az boards work-item show --id <existing-id> --org https://dev.azure.com/<org> --output json
az boards area project list --project <project> --org https://dev.azure.com/<org>
az boards iteration project list --project <project> --org https://dev.azure.com/<org>
```

Use these commands to confirm valid work item types and area/iteration path
values before building a create/update payload. Do not guess field values that
have not been confirmed against the project.

## 6. Read Operations

ID-scoped reads need only the org:

```bash
az boards work-item show --id <id> --org https://dev.azure.com/<org>
az repos pr show --id <id> --org https://dev.azure.com/<org>
```

Project-scoped reads need org and project:

```bash
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType] FROM WorkItems WHERE [System.TeamProject] = '<project>' AND [System.WorkItemType] IN ('Bug', 'Defect') ORDER BY [System.ChangedDate] DESC" --org https://dev.azure.com/<org>
az repos pr list --project <project> --org https://dev.azure.com/<org>
```

Summarize results for the user rather than dumping raw CLI output. If a broad
WIQL query returns many rows, save the full output and summarize the important
items.

## 7. Write Operations

All write operations are project-scoped. Creates and updates also require
schema checks from step 5. For any create, comment, state-change, or link
operation:

1. Build the exact `az` command and exact field values.
2. Show the user the full command and payload verbatim, including the resolved
   org/project target.
3. Ask for explicit confirmation before running it.
4. Execute it only after confirmation.

Examples:

```bash
az boards work-item create --type "<type>" --title "<title>" --org https://dev.azure.com/<org> --project <project>
az repos pr create --title "<title>" --description "<body>" --org https://dev.azure.com/<org> --project <project> --repository <repo> --target-branch main
az boards work-item update --id <id> --state "<state>" --org https://dev.azure.com/<org>
az repos pr work-item add --id <pr-id> --work-items <work-item-id> --org https://dev.azure.com/<org>
```

Preview the exact linking reference or comment text before posting, same as any
other write.

## Gotchas

- `az account show` fails or shows no account: walk through `az login`
  interactively.
- `azure-devops` extension missing: `az boards` and `az repos` commands fail
  with an unrecognized-command error until the extension is installed.
- Do not ask "which project?" for a bare ID. Work item and PR IDs are unique
  org-wide.
- `AZURE_DEVOPS_PROJECTS` unset for a project-scoped operation: treat as
  first-run and ask which project or projects to use.
- One configured project is not the same as safe to assume. State the resolved
  org/project before running anything.
- Ambiguous project target: if more than one project is configured and the
  request does not name one, ask.
- Work item schemas vary by project. Never reuse field values discovered in one
  project for another without re-running step 5.
- Write operations: never skip preview and confirmation, even for a one-line
  comment.

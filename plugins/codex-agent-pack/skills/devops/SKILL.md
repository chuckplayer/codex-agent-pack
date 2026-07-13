---
name: devops
description: "Use when unsure whether a request is a GitHub or Azure DevOps operation, or when someone asks for DevOps help, work items, PRs, issues, or repository triage. Routes to devops-github or devops-azure based on intent."
---

# DevOps Help

The DevOps skill family reads and writes GitHub and Azure DevOps through their
native CLIs, `gh` and `az`. Each platform-specific skill owns setup, auth,
targeting, and write safety for its platform.

## Skills

| Skill | Use when |
|---|---|
| `devops-github` | GitHub PRs and issues for repos configured in `GITHUB_ORG` and `GITHUB_REPOS` |
| `devops-azure` | Azure DevOps work items and PRs for org/projects configured in `AZURE_DEVOPS_ORG` and `AZURE_DEVOPS_PROJECTS` |

## 1. Identify Intent

If the request does not already make the platform obvious, ask the user one
question: **"GitHub or Azure DevOps?"**

Listen for these signals first, since they often make the question unnecessary:

- GitHub: "issue", "pull request", "PR #N", or a repo name matching
  `GITHUB_REPOS`.
- Azure DevOps: "work item", "board", "sprint", "bug", "defect", a project
  name matching `AZURE_DEVOPS_PROJECTS`, or the configured
  `AZURE_DEVOPS_ORG`.

If signals conflict or neither is present, ask directly rather than guessing.

## 2. Route

Once intent is clear, tell the user which skill handles it, then use that
platform-specific skill. For example: "That's Azure DevOps. I am using the
`devops-azure` skill."

## Gotchas

- Do not perform platform operations from this router. `devops-github` and
  `devops-azure` handle setup, auth, targeting, and execution independently.
- Environment variables are each sub-skill's concern. Do not check
  `GITHUB_REPOS` or `AZURE_DEVOPS_PROJECTS` here.
- If the user wants both platforms, route to whichever one they mentioned first
  and note that the other skill can be used as a separate follow-up.

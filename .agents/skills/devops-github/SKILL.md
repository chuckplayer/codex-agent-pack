---
name: devops-github
description: "Read and create GitHub PRs and issues via the gh CLI for repos configured in GITHUB_ORG/GITHUB_REPOS. Use for one-off GitHub repository operations outside the code pipeline: viewing PRs or issues, commenting, changing state, linking commits, or smoke-testing the gh CLI. Do NOT use for Azure DevOps boards/work items. Do NOT use for full code review or implementation work; use review-pr or implement instead."
---

# GitHub DevOps

Read and write GitHub PRs and issues by shelling out to the `gh` CLI. This
skill handles first-time setup, strict repo targeting, and safe write operations
for repositories configured through environment variables or the Codex Agent
Pack env file.

## 1. Verify Setup

Check, in order:

1. `gh` CLI installed: run `gh --version`. If missing, stop and direct the user
   to install it from <https://cli.github.com>.
2. Authenticated: run `gh auth status`. If not logged in, walk the user through
   `gh auth login` interactively. Do not script credentials, store a PAT in
   plaintext, or ask the user to paste a PAT into chat.
3. Environment loaded: check `GITHUB_ORG` and `GITHUB_REPOS`.

Before checking the environment, load the Codex Agent Pack env file if it
exists:

```bash
env_file="${CODEX_AGENT_PACK_ENV_FILE:-${CODEX_HOME:-$HOME/.codex}/agent-pack/env.sh}"
if [ -f "$env_file" ]; then
  . "$env_file"
fi
```

`GITHUB_REPOS` is a comma-delimited list, for example
`GITHUB_REPOS=repo-a,repo-b`. If either value is unset, ask the user for the org
and repo or repos they want to work with. Do not hardcode an org or repo into
this skill.

Report each check's result clearly before proceeding.

## 1a. Persisting or Changing GitHub Targets

Use `scripts/set-env.sh` to persist DevOps target variables for future Codex
sessions. It writes a shell-loadable env file at:

```text
${CODEX_AGENT_PACK_ENV_FILE:-${CODEX_HOME:-$HOME/.codex}/agent-pack/env.sh}
```

After confirming a new or changed value with the user, ask whether to persist
it. If yes:

```bash
bash scripts/set-env.sh GITHUB_ORG=<org> GITHUB_REPOS=<repo-a,repo-b>
```

Never hand-edit Codex config files or write shell-profile export lines to
persist these values. Use `scripts/set-env.sh` so the write is consistent across
macOS, Linux, and Windows with Git Bash.

A session-only value can be exported in the current shell or bypassed by passing
`--repo <org>/<repo>` explicitly for the current command.

## 2. Resolve the Target Repo

Repo targeting must be unambiguous every time:

1. Parse `GITHUB_REPOS` into a list. If the current working directory is inside
   a git repo, also read its remote with `git remote get-url origin`.
2. If the user names a repo explicitly, it must match one of the configured
   `GITHUB_REPOS` entries case-insensitively. If it does not match, ask the user
   to correct it or add it to `GITHUB_REPOS`. Never silently substitute another
   configured repo.
3. If no repo is named and only one is configured, use it, but state the
   resolved repo before running anything. Example: "Using `org/repo-a`,
   configured via `GITHUB_REPOS`."
4. If no repo is named and multiple are configured, ask the user to
   disambiguate before running any `gh` command.
5. If the local git remote disagrees with the resolved target, stop and flag the
   mismatch explicitly. Ask the user to confirm which repo they mean before
   proceeding.

## 3. Identify the Operation

Ask or infer whether the user wants to read or write:

- Read: list or view PRs, issues, checks, or comments. No confirmation is
  needed for read-only commands.
- Write: create a PR or issue, comment, change state, merge, or link a commit.
  Always preview first.

## 4. Read Operations

Run common reads with `--repo <org>/<repo>` resolved from step 2:

```bash
gh pr list --repo <org>/<repo>
gh pr view <number> --repo <org>/<repo>
gh issue list --repo <org>/<repo>
gh issue view <number> --repo <org>/<repo>
```

Summarize results for the user rather than dumping raw CLI output.

## 5. Write Operations

For any create, comment, state-change, merge, or link operation:

1. Build the exact `gh` command and, for multi-line bodies, the exact text that
   will be posted.
2. Show the user the full command and payload verbatim, including the resolved
   `--repo <org>/<repo>` target.
3. Ask for explicit confirmation before running it.
4. Execute it only after confirmation.

Examples:

```bash
gh issue create --repo <org>/<repo> --title "<title>" --body "<body>"
gh pr create --repo <org>/<repo> --title "<title>" --body "<body>" --base main
gh issue comment <number> --repo <org>/<repo> --body "<comment>"
gh issue close <number> --repo <org>/<repo>
```

Linking a commit to an issue is done through a `Fixes #<number>` or
`Closes #<number>` reference in a commit message, PR body, or issue body.
Preview the exact reference text before including it.

## Gotchas

- `gh auth status` fails or shows no host: walk through `gh auth login`
  interactively. Let `gh` handle the browser or token flow.
- `GITHUB_REPOS` unset: treat as first-run. Ask which org/repo or repos to use
  instead of defaulting silently to the current git remote.
- One configured repo is not the same as safe to assume. State the resolved repo
  before running anything and cross-check it against the local git remote when
  one exists.
- Ambiguous repo target: if more than one repo is configured and the request
  does not name one, ask. Never guess which repo a bare issue or PR number
  belongs to.
- Configured repo vs. local git remote mismatch: stop and ask which target is
  correct.
- Write operations: never skip preview and confirmation, even for a one-line
  comment.

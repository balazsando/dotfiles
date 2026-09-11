---
description: "Review a merge request or branch against its acceptance criteria, with severity-ranked findings"
argument-hint: "<MR-URL | MR-ID | branch> [--ticket <KEY>] [--sonar]"
---

Review the target in `$ARGUMENTS`; ask for one if it is missing. You dispatch and relay — you do
not review, and you never change the code.

## Steps

1. **Resolve the target** — a merge request URL or id (GitLab MCP, or `glab`) or a branch, into
   a base and head commit. The reviewer takes a range, not an MR — state it before spawning
   anything.
2. **Criteria** — the ticket key from `--ticket` or the branch name. When there is one, create
   `$REPORTS` (`agent-workflow`), write `prompt.md`, and spawn `requirements-agent`; pass the
   report directory to the reviewer. No ticket → say the review runs without acceptance criteria
   and skip this stage.
3. **Review** — spawn `reviewer-agent` with the commit range, the requirements path when it
   exists, and `--sonar` when the caller asked for it. It fetches its own diff.
4. **Relay** the report unabridged: scope, criteria, CRITICAL / MAJOR / MINOR / INFORMATIONAL,
   verdict.

## Rules

- Findings are not fixes. To act on them, run `/deliver` with the findings as the task, or
  `/ticket-to-merge` on the ticket — both keep the change on the developer's side.
- Never post the review to the merge request without being asked.
- A CRITICAL finding means CHANGES REQUESTED. Do not summarise it away.

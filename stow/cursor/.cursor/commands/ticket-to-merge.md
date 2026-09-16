---
description: "Implement a Jira ticket through the delivery agents and open a merge request"
---

`/deliver --from <TICKET-KEY>`, plus the repository, branch and merge-request half. Extract the key
from the text after `/ticket-to-merge`; ask for one if it is missing. You orchestrate; the agents
commit.

Load `orchestration`. Branch mechanics are `change-delivery`.
This command carries the `git` rule's commit exception, on this
run's own ticket branch and nowhere else. Never touch existing history.

## Rules

- The steps are `/deliver`'s. This command owns the repository, `$REPORTS`/`prompt.md`, the
  preconditions and the branch; `/deliver` never runs them twice.
- Ask before pushing to a shared branch and before commenting on an existing merge request.

## Run

1. **Repository** — if the current directory is not the right repo, read the ticket's component
   and labels through `jira-tickets` and match them against the repositories under `$REPOS_DIR`.
   Rank the candidates and ask only when the ranking is genuinely tied. `$REPOS_DIR` unset → ask.
2. **Preconditions and base branch** — `change-delivery` §1–2. A dirty tree stops the run.
   Create `$REPORTS` and write `prompt.md`.
3. **Branch** — `change-delivery` §3, before the first delegation.
4. **Steps** — `/deliver`'s, with the ticket as the plan's source. None of them removes the
   branch, the agents' builds, their commits, or the merge request.
5. **Push and merge request** — the agents' atomic commits are the branch history; never squash
   or rewrite them. Push the ticket branch, open the MR (GitLab MCP, or `glab` when the MCP
   cannot), link the ticket, and state the criteria coverage and the assumptions made.
6. **Pipeline** — watch it. A failure routes like any other defect: implementation → developer,
   contract or design → plan agent. Never fix a pipeline by weakening a test.

## Report

`change-delivery` §6, plus the merge request URL.

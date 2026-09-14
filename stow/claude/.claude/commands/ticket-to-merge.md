---
description: "Implement a Jira ticket through the specialised roles and open a merge request"
argument-hint: "<TICKET-KEY> [additional instructions]"
---

`/deliver --from <TICKET-KEY>`, plus the branch and merge-request half. Extract the key from
`$ARGUMENTS`; ask for one if it is missing. You orchestrate; the agents commit.

Load `orchestration`. Branch mechanics are `change-delivery`.
This command carries the `~/.claude/CLAUDE.md` **Git operations** commit exception, on this
run's own ticket branch and nowhere else. Never touch existing history.

## Rules

- Sizing and the agent sequence are `/deliver`'s. Follow that command from its sizing step; this
  one owns `$REPORTS`/`prompt.md`, preconditions, and the branch. The requirements agent always
  runs — the ticket is the source of truth.
- Ask before pushing to a shared branch and before commenting on an existing merge request.

## Steps

1. **Preconditions and base branch** — `change-delivery` §1–2. A dirty tree stops the run.
   Create `$REPORTS` and write `prompt.md`.
2. **Requirements** — the requirements agent. A `func` question reaches the user before anything
   else; a ticket with no testable criterion is a stop condition, not a guess.
3. **Repository** — if the current directory is not the right repo, match the ticket's component
   and labels against the repositories under `$REPOS_DIR`. Rank the candidates and ask only when
   the ranking is genuinely tied. `$REPOS_DIR` unset → ask.
4. **Branch** — `change-delivery` §3, before the first spawn that edits.
5. **Flow** — `/deliver` sizes it and runs it, from its sizing step: `$REPORTS`/`prompt.md`, the
   preconditions, and the branch are steps 1 and 4 above and never run twice. Size never removes
   the branch, the agents' builds, their commits, or the merge request.
6. **Push and merge request** — the agents' atomic commits are the branch history; never squash
   or rewrite them. Push the ticket branch, open the MR (GitLab MCP, or `glab` when the MCP
   cannot), link the ticket, and state the criteria coverage and the assumptions made.
7. **Pipeline** — watch it. A failure routes like any other defect: implementation → developer,
   design → the agent that wrote `design.md`. Never fix a pipeline by weakening a test.

## Report

`change-delivery` §6, plus the merge request URL.

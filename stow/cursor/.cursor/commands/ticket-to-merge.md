---
description: "Implement a Jira ticket through the specialised roles and open a merge request"
---

`/deliver --from <TICKET-KEY>`, plus the git and merge-request half. Extract the key from the
text after `/ticket-to-merge`; ask for one if it is missing. You orchestrate and own git — no
agent commits.

## Rules

- The workspace, roster, hand-off and routing rules are `/deliver`'s. Follow that command; this
  one adds only what surrounds it. Stage 1 always runs — the ticket is the source of truth.
- Branch, validation, coverage, commit and report mechanics: `change-delivery` skill. Load it.
- This command carries the `git` rule's commit exception, on this run's own ticket branch and
  nowhere else. Never touch existing history.
- Ask before pushing to a shared branch and before commenting on an existing merge request.

## Steps

1. **Preconditions and base branch** — `change-delivery` §1–2. A dirty tree stops the run.
2. **Requirements** — `requirements-agent`. A blocking question goes to the user before anything
   else; a ticket with no testable criterion is a stop condition, not a guess.
3. **Repository** — if the current directory is not the right repo, match the ticket's
   component and labels against the repositories under `$REPOS_DIR`. Rank the candidates and ask
   only when the ranking is genuinely tied. `$REPOS_DIR` unset → ask.
4. **Branch** — `change-delivery` §3, before the first edit.
5. **Size, then design → implement → test → review → fix → document** — `/deliver` §Sizing
   picks the roster, then its stages 2–7, same conditions, same routing. Size never removes a
   step below: the branch, the build, the review, the commit and the merge request run whatever
   the size.
6. **Commit** — `change-delivery` §5. One commit; the body lists each criterion and how it is
   met.
7. **Push and merge request** — push the ticket branch, open the MR (GitLab MCP, or `glab` when
   the MCP cannot), link the ticket, and state the criteria coverage and the assumptions made.
   No tooling attribution in the description — the commit hook cannot strip it there.
8. **Pipeline** — watch it. A failure routes like any other defect: implementation → developer,
   design → architect. Never fix a pipeline by weakening a test.

## Report

The `change-delivery` §6 hand-back, plus the criteria and their status, the reviewer's verdict,
the merge request URL, the pipeline result, and every assumption and open question.

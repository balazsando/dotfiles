---
description: "Deliver a change from a Jira ticket or a plain-text task on its own branch, up to a merge request"
---

Deliver the change named after `/deliver`.

Load `change-delivery` for branch, validation, commit and report mechanics, and `jira-tickets`
when there is a ticket. This command carries the `git` rule's commit exception, on this run's
own branch and nowhere else.

## Input

A leading ticket key (`ABC-123`, or a bare number per `jira-tickets`) is the ticket; the rest,
minus flags, is the task or a clarification. Nothing → ask.

Text next to a ticket refines it for this run only and wins where it is more specific; ask when
it contradicts a criterion or widens the scope. The ticket is never edited.

`--no-docs` skips Document. `--ultra` runs every phase at ponytail ultra. `--mr` pushes and opens
a merge request; without it the run ends with local commits.

## Phases

Run a phase only when the change needs it; name the skipped ones in one line.

1. **Requirements** — the ticket with its comments and links, or the text. Read `/docs`,
   `README.md` and the repositories in `~/.cursor/local/doc-repos.md` only for a gap. State the
   criteria and assumptions. No testable criterion, or a business decision needed → ask. A ticket
   for another repository → pick it under `$REPOS_DIR` by component and labels; ask on a tie.
2. **Plan** — only when the change is more than one obvious edit: the smallest design that fits
   the repository, no refactor the criteria did not ask for.
3. **Build** — `change-delivery` §1–3, then implement with the language skills the code needs.
   Branch `<feature|fix|refactor|chore>/<slug>`, whichever fits; start the slug with the ticket
   key when known (`feature/ABC-123-add-widget`) — the `prepare-commit-msg` hook only matches
   `[A-Z][A-Z0-9]+-[0-9]+` in the branch name. Reuse the current branch instead only when it is
   not protected and carries the ticket key or matches the subject; say so.
4. **Validate** — a test per criterion (`atdd` for feature, API or domain tests), then
   `change-delivery` §4 green with its coverage rule. Skipped only when the diff has nothing to
   assert. Never weaken, skip or delete an existing test.
5. **Document** — update `/docs` and `README.md` where they name a symbol, command, path or flag
   the diff touched. Propose an ADR only for a high-impact or lock-in decision.

Ponytail runs `full`; switch to `ultra` for Build and Validate and back for Document, or stay
`ultra` throughout with `--ultra`. No level waives a criterion, a test, coverage, or a doc update.

## Commits

Build, Validate and Document each end with their own commit per `change-delivery` §5 — `feat-`,
`fix-` or `refactor-` for Build, `test-` for Validate, `docs-` for Document. Each commit is atomic:
one concern, and the build is green at that commit. A production fix found in Validate is
its own `fix-` commit, never an amend.

## Merge request

With `--mr`: push, open the merge request (GitLab MCP, or `glab`) linking any ticket, and watch the
pipeline — fix a failure with a new commit. Ask before pushing to a shared branch or commenting on
an existing merge request.

Report per `change-delivery` §6, plus criteria coverage and the merge request URL.

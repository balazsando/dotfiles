---
description: "Deliver a change from a Jira ticket or a plain-text task on its own branch, up to a merge request"
argument-hint: "<TICKET-KEY | task> [clarification] [--no-docs]"
---

Deliver the change in `$ARGUMENTS`.

Load `change-delivery` for branch, validation, commit and report mechanics, and `jira-tickets`
when there is a ticket. This command carries the `~/.claude/CLAUDE.md` **Git operations** commit
exception, on this run's own branch and nowhere else.

## Input

A leading ticket key (`ABC-123`, or a bare number per `jira-tickets`) is the ticket; the rest of
the text, minus flags, is the task or the clarification.

| Input | Criteria from | Ends with |
| --- | --- | --- |
| Ticket | the ticket | push and merge request |
| Ticket + text | the ticket, refined by the text | push and merge request |
| Text | the text | local commits; ask before pushing |
| Nothing | ask | — |

**Clarification** refines the ticket for this run only; the ticket itself is never edited. Where
the text is more specific, it wins. Where it contradicts a ticket criterion or widens the scope,
ask before editing. State which criteria it changed.

## Rules

- Never present an inference as a source. No testable criterion in any source, or the intent needs
  a business decision → ask.
- The design that fits the repository beats a blank-page one: smallest structure that satisfies
  the criteria, no refactor they did not ask for.
- Never weaken, skip or delete an existing test to make the code fit.
- Ask before pushing to a shared branch and before commenting on an existing merge request.

## Steps

1. **Repository** — with a ticket, when the current directory is not the right repo, match the
   ticket's component and labels against the repositories under `$REPOS_DIR`; ask only when the
   ranking is tied, or when `$REPOS_DIR` is unset. Without one, the current repository.
2. **Preconditions and base branch** — `change-delivery` §1–2.
3. **Criteria** — the ticket with its comments and links, or the text. Read further only where
   those leave a gap: the repository's `/docs` and `README.md`, then the documentation
   repositories in `~/.claude/local/doc-repos.md` (missing → say so). State the criteria and
   assumptions before branching.
4. **Branch** — `change-delivery` §3, before the first edit. With a ticket, the slug starts with
   its key.
5. **Tests** — for the criteria: `atdd` for feature, API or domain tests, `java-standards`
   `references/tests.md` for Java. Skipped only when the diff has nothing to assert —
   documentation, formatter output, configuration no runtime reads.
6. **Implement** — with the language skills the code needs (`java-standards`, then `clean-code`,
   for Java/Spring/Maven), until `change-delivery` §4 is green.
7. **Documentation** — unless `--no-docs`, update `/docs` and `README.md` where they name a
   symbol, command, path or flag the diff touched. Propose an ADR only for a high-impact or
   lock-in decision; write it once the user confirms.
8. **Commit** — `change-delivery` §5.
9. **Push and merge request** — with a ticket, or when the user agrees: push the branch, open the
   MR (GitLab MCP, or `glab`), link the ticket when there is one, and state criteria coverage and
   assumptions.
10. **Pipeline** — when pushed, watch it. Fix a failure with a new commit on the branch; never by
    weakening a test.

## Done when

Every criterion is met or waived by the user, the tests pass, and coverage is met or its shortfall
justified. Report per `change-delivery` §6, plus the merge request URL.

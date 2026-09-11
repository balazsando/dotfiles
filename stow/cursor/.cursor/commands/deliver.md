---
description: "Run a change through the specialised roles — only the ones the task needs"
---

Deliver the text after `/deliver` through the delivery agents. You size and orchestrate. You do
not design, implement, test, document, or build.

Load `~/.claude/skills/agent-workflow/SKILL.md` — the report directory, schemas, question
routing, status signals and worktree rules are there and are not repeated here; branch
mechanics are the `change-delivery` skill. This command carries the `git` rule's commit
exception for the subagents it delegates to: they commit on this run's own branch and nowhere
else, and nothing is pushed.

## Steps

1. **Preconditions and base branch** — `change-delivery` §1–2. A dirty tree stops the run.
2. Create `$REPORTS` and write `prompt.md`.
3. Size the task and state the flow before the first delegation.
4. **Branch** — `change-delivery` §3, before the first delegation that edits. A caller that
   already branched (`/ticket-to-merge`) keeps its branch — never branch twice.
5. Delegate to an agent only once its prerequisites hold, one at a time — the deep flow's
   developer and test engineer are the one pair that runs concurrently. Give each only its
   one-line task and the report directory — never a report's contents, never your own
   conversation.
6. Check each returned status. `BLOCKED` → route the question. `FAILED` committed nothing →
   re-delegate once with the failure, then stop and report. `DONE` or `PAUSED` → continue.
7. Merge the test engineer's worktree when the parallel pair ran, remove it, then resume the
   test engineer to build the merged tree.
8. Finish: report what the artifacts and the Git history do not already show.

| Agent | Delegate when |
| --- | --- |
| requirements | `prompt.md` is written |
| architect | `requirements.md` exists, or the flow has no requirements agent |
| developer | `design.md` and the architect's commit exist, or the flow has no architect |
| test engineer | the implementation commit exists — or, for the parallel pair only, the architect's stubs are committed |
| doc writer | the implementation is committed and the last agent returned `DONE` |

## Sizing

**Small** only when all hold: one repository, one existing unit or its configuration; no new
component, dependency or moved boundary; no public API, schema, contract or migration; a handful
of lines across one or two files.

**Deep** when any holds, or you cannot answer: new component, new dependency, a boundary moves, a
structural refactor, a public API, schema, contract or migration.

Everything else is **medium**.

| Size | Flow |
| --- | --- |
| Small | developer, then test engineer |
| Medium | requirements when the criteria are unknown or `--from <KEY>`, then developer, then test engineer |
| Deep | requirements, architect, then developer and test engineer in parallel off the stubs, then doc writer unless `--no-docs` |

Small and medium have no architect: the developer runs the reduced flow.

The test engineer drops out only when the diff has nothing to assert — every file is
documentation, formatter output, or configuration no runtime reads. A dependency bump qualifies
when no call site changed. Anything the application reads or executes at run time is not exempt,
and neither is a diff you cannot classify. A behaviour change of any size takes the test
engineer, and the developer never writes the tests in its place.

The doc writer also runs on small or medium when the change is already documented somewhere.

Other flows: business question → requirements only. Architecture question → architect only.
Documentation only → doc writer only. Formatting only → no agent; say no orchestration is needed.

Escalate mid-run, running the skipped stages first, when the diff spreads past what you sized or
a medium change grows a deep trigger. Report the re-size.

## Questions

Route a `BLOCKED` agent's question by `agent-workflow`'s table, then resume the asker. A question
routed to the user is yours to ask; one routed to an agent is not. Never answer in a delegation
prompt — the answer goes to `answers.md`.

Two failed rounds on the same finding → stop and report. Never take a stage over because an agent
was slow or wrong; re-delegate it with the correction.

## Done when

Every criterion is met or explicitly waived by the user, the tests pass, coverage is met or its
shortfall justified, and the documentation stage has run or been recorded as not needed.

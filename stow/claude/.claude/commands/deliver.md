---
description: "Run a change through the specialised roles — only the ones the task needs"
argument-hint: "<task description> [--from <TICKET-KEY>] [--no-docs]"
---

Deliver `$ARGUMENTS` through the delivery agents. You size and orchestrate. You do not design,
implement, test, document, or build.

Load `orchestration`. Branch mechanics are `change-delivery`.
This command carries the `~/.claude/CLAUDE.md` **Git operations** commit exception for the
agents it spawns: they commit on this run's own branch and nowhere else, and nothing is pushed.

## Steps

1. **Preconditions and base branch** — `change-delivery` §1–2. A dirty tree stops the run.
2. Create `$REPORTS` and write `prompt.md`.
3. Size the task and state the flow before the first spawn.
4. **Branch** — `change-delivery` §3, before the first spawn that edits. A caller that already
   branched (`/ticket-to-merge`) keeps its branch — never branch twice.
5. Spawn an agent only once its prerequisites hold, one at a time. Tests before implementation.
6. Check each returned status.
7. **Hand back** — `change-delivery` §6.

| Agent | Spawn when |
| --- | --- |
| requirements | `prompt.md` is written |
| architect | the flow includes one, and `requirements.md` exists or the flow has no requirements agent |
| test engineer | `design.md` and the architect's commit exist, or the flow has no architect |
| developer | the test engineer's commit exists, or the test engineer was dropped |
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
| Small | test engineer, then developer |
| Medium | requirements when the criteria are unknown or `--from <KEY>`, then test engineer, then developer |
| Deep | requirements, architect, test engineer, developer, then doc writer unless `--no-docs` |

Small and medium have no architect: the test engineer owns the technical design.

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

Route a `BLOCKED` agent's question per orchestration, then resume the asker.

Two failed rounds on the same finding → stop and report.

## Done when

Every criterion is met or explicitly waived by the user, the tests pass, coverage is met or its
shortfall justified, and the documentation stage has run or been recorded as not needed.

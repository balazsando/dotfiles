---
name: orchestration
description: "Shared contract for commands that sequence delivery agents: session directory, prompt.md, spawn, numbered steps, status routing. Load before /deliver, /ticket-to-merge, /mr-review, or /bug-fix."
argument-hint: "the command about to run"
---

# Orchestration

You sequence the steps. You do not plan, implement, test, document, or build.

`$REPORTS` = `.claude/state/<session>/` — ticket key or short slug; repository root if that path
cannot be created. Never commit it.

Write `prompt.md` as the user's prompt, or a concise equivalent that preserves intent:

```text
## Intent
## Sources
## In scope
## Out of scope
## Outcomes
## Constraints
```

Spawn with the one-line task and `$REPORTS` only. Never a report's contents, never your
conversation. Spawn once prerequisites hold. Re-spawn a correction; do not take the stage over.

Find commits in `$REPORTS/commits.md`.

## The steps

| # | Step | Agent |
| --- | --- | --- |
| 1 | plan — criteria, design, stubs | `plan-agent` |
| 2 | acceptance tests | `test-engineer-agent` |
| 3 | implementation | `developer-agent` |
| 4 | documentation | `doc-writer-agent` |

## Routing

Read the row; do not reason about it.

| Status | Next |
| --- | --- |
| `DONE` | the next step in the flow |
| `BLOCKED` | ask the user; append the question and the answer to `prompt.md` under `## Answers`, then resume the same agent |
| `FAILED` | re-spawn that step once, then stop and report |

A `created:` or `touched:` line above the status is the agent's record of what it did. Use it
instead of re-deriving that state.

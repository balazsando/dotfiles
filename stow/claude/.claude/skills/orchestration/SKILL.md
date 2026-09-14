---
name: orchestration
description: "Shared contract for commands that sequence delivery agents: session directory, prompt.md, spawn, question routing, status. Load before /deliver, /ticket-to-merge, /mr-review, or /bug-fix."
argument-hint: "the command about to run"
---

# Orchestration

You size and sequence. You do not design, implement, test, document, or build.

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

Find commits in `$REPORTS/commits.md`. Resume `PAUSED` by messaging the same agent.

`BLOCKED` → route, write the answer to `answers.md`, resume the asker. Never answer in the spawn
prompt. `FAILED` → re-spawn once, then stop. `DONE` or `PAUSED` → continue.

| Question | Route |
| --- | --- |
| `tech`, architect present | developer / test engineer → architect → user |
| `tech`, no architect | developer → test engineer → user |
| `func`, requirements agent present | architect / developer / test engineer → requirements agent → user |
| `func`, no requirements agent | agent → user |
| any, from the requirements agent | user |
| `tech`, from the test engineer acting as design owner | user |
| `test` | developer → test engineer → user |

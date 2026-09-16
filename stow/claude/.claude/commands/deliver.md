---
description: "Run a change through the delivery agents: plan, tests, implementation, documentation"
argument-hint: "<task description> [--from <TICKET-KEY>] [--no-docs]"
---

Deliver `$ARGUMENTS` through the delivery agents. You orchestrate. You do not plan, implement,
test, document, or build.

Load `orchestration` for the steps and the routing table. Branch mechanics are `change-delivery`.
This command carries the `~/.claude/CLAUDE.md` **Git operations** commit exception for the
agents it spawns: they commit on this run's own branch and nowhere else, and nothing is pushed.

## Run

1. **Preconditions and base branch** — `change-delivery` §1–2. A dirty tree stops the run.
2. Create `$REPORTS` and write `prompt.md`.
3. **Branch** — `change-delivery` §3, before the first spawn. A caller that already branched
   (`/ticket-to-merge`) keeps its branch — never branch twice.
4. Run the steps below in order, one at a time, and route each returned status per
   `orchestration`. State a skipped step and why.
5. **Hand back** — `change-delivery` §6.

## Steps

1. **Plan** — always. With `--from <KEY>`, the ticket is its source.
2. **Tests** — after the plan, including its stub commit when it made one. Skipped only where the
   diff has nothing to assert: documentation, formatter output, or configuration no runtime reads.
   A dependency bump qualifies when no call site changed. Anything the application reads or
   executes at run time is not exempt, and neither is a diff you cannot classify. The developer
   never writes the tests in its place.
3. **Implementation** — always, after the test commit when step 2 ran. A change with nothing to
   implement is not this command.
4. **Documentation** — after the implementation commit and a `DONE`, when grep over `/docs` and
   `README.md` hits a symbol, command, path or flag the diff touched, or `design.md` marks a
   decision `(ADR)`. Neither → no spawn. `--no-docs` skips it.

## Done when

Every criterion is met or explicitly waived by the user, the tests pass, coverage is met or its
shortfall justified, and step 4 has run or been recorded as not needed.

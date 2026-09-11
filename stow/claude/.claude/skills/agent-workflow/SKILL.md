---
name: agent-workflow
description: "The contract delivery agents share: the session report directory, the report schemas, question routing, blocking, and status signals. Load before running requirements-agent, architect-agent, developer-agent, test-engineer-agent, doc-writer-agent, or an orchestrating command."
argument-hint: "the agent or command about to run"
---

# Agent workflow

Agents never call each other and never relay through command arguments. They communicate through
`.md` reports in one session directory, and signal a status.

## Session report directory

`$REPORTS` = `.claude/state/<session>/`, `<session>` being the ticket key or a short task slug —
the repository root when that directory cannot be created. Reports are workspace artifacts: never
commit `$REPORTS`.

## Lifecycle

```text
read required reports
read questions when applicable
read answers when applicable
read the prior commit when applicable
do task
optional: write question -> BLOCKED
atomic commit, when you changed files
write report -> DONE
```

Your own brief names the reports you read and write, and the build bar you reach before you are
done. Build the modules you touched with the project's own build (`change-delivery` §4) and
commit per its §5. The prior commit is the architect's for the developer, and the relevant
implementation commit for the test engineer and the doc writer. `FAILED` commits nothing.

## Schemas

Reports are contracts. Write only what the reader cannot derive from the repository, the stubs,
the Git diff, or another report — never duplicate between reports, never restate the prompt, and
create no report the flow does not need.

`prompt.md` — the user's prompt verbatim, or a concise equivalent when that measurably helps
execution. Intent is preserved exactly. Every reference to it uses the name `prompt.md`.

`requirements.md` — requirements and the functional context downstream agents need, nothing else.

```text
## User Story
## Context
## Acceptance Criteria
```

`design.md`, and `developer-design.md` with the same schema:

```text
## Goal
## Flow
## Decisions
## Constraints
```

Implementation-relevant decisions and flow only. Never explain what an interface, a stub, or the
existing code already shows.

`test-fail.md` — written by the test engineer when a failure needs developer action:

```text
## Failures
- <symptom> — `file:line` — implementation | design | criteria
```

## Questions and blocking

Two types: `tech` (implementation or architecture) and `func` (functional or business). Write them
to `$REPORTS/questions.md`; answers land in `$REPORTS/answers.md`.

```text
## Q<n> tech|func — from <agent> — to <agent|user>
<question>
```

```text
## Q<n> — by <agent|user>
<answer>
```

| Question | Route |
| --- | --- |
| `tech`, architect present | developer / test engineer → architect → user |
| `tech`, no architect | developer / test engineer → user |
| `func`, requirements agent present | architect / developer / test engineer → requirements agent → user |
| `func`, no requirements agent | agent → user |
| any, from the requirements agent | user |

A relaying agent answers what it can from its own authority and escalates to the user only when
user input is genuinely required. Writing a question ends the turn as `BLOCKED`. An agent is also
`BLOCKED` when a required report or commit is missing.

## Status

The final line of the return is one token — `DONE`, `BLOCKED`, `PAUSED`, or `FAILED` — and nothing
else. The status is a signal, never a substitute for the report.

`PAUSED` means the work is complete and the agent stays resumable until the orchestration ends, so
a later question reaches it without a cold restart. An orchestrator resumes it by messaging that
same agent, never by spawning a second one.

## Reduced flows

No `design.md` — the developer inspects the task and the existing code, writes
`developer-design.md` when the task needs a technical design, and sends `tech` questions to the
user.

No `requirements.md` — the developer reads `prompt.md` directly; routing is unchanged.

## Parallel developer and test engineer

Only against a frozen contract both read before starting — the architect's stubs — and with
isolated trees. The developer works in the main worktree, the test engineer in its own
(`git worktree add --detach <path> HEAD`), against the code state available to it and off the
files the developer owns. Both commit atomically in their own tree; neither merges.

The test engineer returns `PAUSED`, not `DONE`, until the trees are one. Once the orchestrator has
merged its worktree it resumes the test engineer, which builds the merged tree with the tests —
that build is the pair's green bar. What it cannot fix from the test side goes to the developer as
`test-fail.md`.

No safe isolation means no concurrency: run the two in order instead.

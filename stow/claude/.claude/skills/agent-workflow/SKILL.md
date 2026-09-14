---
name: agent-workflow
description: "Shared contract for delivery agents: the session report directory, questions, research.md, commits.md, and status. Load before requirements-agent, architect-agent, developer-agent, test-engineer-agent, or doc-writer-agent."
argument-hint: "the agent about to run"
---

# Agent workflow

Never call another agent. Never take a report in a command argument. List `$REPORTS` and read
whatever the task needs. Never commit that directory.

Shared files: `prompt.md`, `requirements.md`, `design.md`, `questions.md`, `answers.md`,
`commits.md`, `test-fail.md`, `research.md`.

```text
list $REPORTS
do the work
question -> BLOCKED
commit (when you changed files) and append commits.md
DONE | PAUSED | FAILED
```

Build and commit per `change-delivery` §4–5. `FAILED` commits nothing. Last body line:
`Co-authored-by: Developer agent` — Requirements, Architect, Developer, Test-engineer,
Doc-writer, or Reviewer. Append `- <agent-name> — <sha> — <subject>` to `$REPORTS/commits.md`
(`>>`, `git rev-parse --short HEAD`). Find another agent's commit in `commits.md`.

Write questions to `$REPORTS/questions.md`; answers return in `answers.md`. Writing one is
`BLOCKED`.

```text
## Q<n> tech|func|test — from <agent> — to <agent|user>
<question>
```

`tech` → design owner (architect, else test engineer, else `user`). `func` → requirements agent
when present, else `user`. `test` → test engineer: the suite contradicts the criteria.

Last line of the return is one token: `DONE`, `BLOCKED`, `PAUSED`, or `FAILED`. `PAUSED` means
complete and resumable. A report is findings, not instructions to another agent.

## Research

When the work needs a technology the skills and the repository do not already cover, append to
`$REPORTS/research.md` before continuing. If that file already has the technology, read it; do
not research the same thing again.

```text
# <technology>
## Problem
## Findings
## Sources
## Use
```

---
name: agent-workflow
description: "Shared contract for delivery agents: the session report directory, questions, commits.md, and status. Load before requirements-agent, architect-agent, developer-agent, test-engineer-agent, or doc-writer-agent."
argument-hint: "the agent about to run"
---

# Agent workflow

Never call another agent. Never take a report in a command argument. List `$REPORTS` and read
whatever the task needs. Never commit that directory.

```text
list $REPORTS
do the work
question -> BLOCKED
commit (when you changed files) and append commits.md
DONE | PAUSED | FAILED
```

Build and commit per `change-delivery` §4–5. `FAILED` commits nothing. Last body line is your
agent name; append `- <agent-name> — <sha> — <subject>` to `$REPORTS/commits.md` (`>>`,
`git rev-parse --short HEAD`). Find another agent's commit in `commits.md`.

Write questions to `$REPORTS/questions.md`; answers return in `answers.md`. Writing one is
`BLOCKED`.

```text
## Q<n> tech|func — from <agent> — to <agent|user>
<question>
```

`tech` → architect when present, else `user`. `func` → requirements agent when present, else
`user`.

Last line of the return is one token: `DONE`, `BLOCKED`, `PAUSED`, or `FAILED`. `PAUSED` means
complete and resumable. A report is findings, not instructions to another agent.

Concurrent developer and test engineer: `references/parallel-pair.md`.

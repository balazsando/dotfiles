---
name: agent-workflow
description: "Shared contract for delivery agents: the session report directory, research.md, commits.md, and status. Load before plan-agent, test-engineer-agent, developer-agent, or doc-writer-agent."
argument-hint: "the agent about to run"
---

# Agent workflow

Never call another agent. Never take a report in a command argument. List `$REPORTS` and read
whatever the task needs. Never commit that directory.

```text
list $REPORTS
do the work
commit (when you changed files) and append commits.md
DONE | BLOCKED | FAILED
```

Build and commit per `change-delivery` §4–5. `FAILED` commits nothing. Last body line:
`Co-authored-by: <Role> agent`, the role from your name (`Test-engineer agent`). Append
`- <agent-name> — <sha> — <subject>` to `$REPORTS/commits.md` (`>>`, `git rev-parse --short HEAD`).
Find another agent's commit in `commits.md`.

Resolve your own unknowns per *Research*. `BLOCKED` is for what no source
settles — a decision that is the user's, an access you do not have, a contradiction you may not
edit away. Put the question above the token; the answer comes back to you.

Last line of the return is one token: `DONE`, `BLOCKED`, or `FAILED`. Above it, state what the
orchestrator would otherwise re-derive. Both lines are optional.

```text
created: <symbols you added>
touched: <paths you changed>
```

## Research

A fact the code does not show is yours to establish, in your own turn and bounded to what the
work needs.

Read `research.md` before researching: if it already has the technology, it is answered. Append
what you found. No research, no `research.md`.

```text
# <technology>
## Problem
## Findings
## Sources
## Use
```

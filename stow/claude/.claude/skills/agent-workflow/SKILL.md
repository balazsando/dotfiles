---
name: agent-workflow
description: "Shared contract for delivery agents: the session report directory, research.md, the knowledge store, commits.md, status, and the lookup-before-search protocol. Load before plan-agent, test-engineer-agent, developer-agent, or doc-writer-agent."
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

Resolve your own unknowns: *Lookup before search*, then *Research*. `BLOCKED` is for what no source
settles — a decision that is the user's, an access you do not have, a contradiction you may not
edit away. Put the question above the token; the answer comes back to you.

Last line of the return is one token: `DONE`, `BLOCKED`, or `FAILED`. Above it, state what the
orchestrator would otherwise re-derive. Both lines are optional.

```text
created: <symbols you added>
touched: <paths you changed>
```

## Lookup before search

Cheapest first; each is an algorithm, not a model call.

1. `~/.claude/knowledge/INDEX.md` — one line per finding. A hit means read that entry and stop.
2. `~/.claude/local/code-index.md` — indexed repositories and their graphs. Query before grepping:
   `graphify query "<q>" --graph <p> --budget 800` locates, with `file:line`;
   `graphify affected "<sym>" --graph <p> --depth 2` is what a change reaches;
   `graphify god-nodes --graph <p> --top 10` is the hubs. Omit `--graph` in a repository that has
   its own `graphify-out/`. Neither index is authoritative — verify a fact you are about to act on.
3. Grep and Read, for the rest.

A missing index is not a blocker: fall through to the next step. Refresh the code index with
`repos-index.sh`; never build a graph mid-task, a first build is not free.

## Research

A fact the three lookup steps miss is yours to establish, in your own turn and bounded to what the
work needs.

Read `research.md` before researching: if it already has the technology, it is answered. Append
what you found, and persist anything a later session would otherwise redo as
`~/.claude/knowledge/<slug>.md` with its `INDEX.md` line. Session-only detail stays out of the
store. No research, no `research.md`.

```text
# <technology>          # the knowledge entry adds frontmatter:
## Problem              #   source: <repo>@<sha> | <url> | <path>
## Findings             #   verified: YYYY-MM-DD
## Sources              #   scope: library | repo | api
## Use
```

`source` and `verified` are how a later reader judges staleness: when the source has moved past
that sha, re-verify the fact you use — not the whole entry.

---
description: "Run a change through the specialised roles — only the ones the task needs"
---

Deliver the text after `/deliver` as a team of narrow agents. You are the orchestrator: you
route, you do not design, implement, test, review, or document. Prepares files only — no branch,
no commit.

## Workspace

`.claude/state/<slug>/` in the current repo, `<slug>` from the ticket key or a short task slug.
Create it. Every stage writes one file there; you pass **paths**, never file contents, and never
your own conversation, to the next agent. Existing files mean a resumed run: skip the stages that
already produced one unless the user asks for a redo.

## Sizing

Size the change before the first spawn — from the task text, or from `requirements.md` when
stage 1 ran. **Small** only when all of these hold:

- one repository, one existing unit or its configuration;
- no new component, no new dependency, no boundary moved;
- no public API, schema, contract or migration touched;
- a handful of lines across one or two files;
- rollback is reverting the commit.

Anything else, or anything you cannot answer, is **full**. State the size and the roster it
selects before spawning.

Small runs stages 3 and 5 — plus 4 when behaviour changed, 7 when the change is documented
somewhere. With no stage 2 there is no `design.md`: both agents get `requirements.md`, or the
task text. Size decides how much design a change gets, never how much validation — the reviewer
and the build run at every size.

Escalate to full mid-run, running the skipped stages first, when the developer returns
`BLOCKED: <technical>`, the diff spreads past the files you sized, or the reviewer returns a
structural CRITICAL or MAJOR. Report the re-size.

## Roster — invoke only what the task needs

| Stage | Agent | Run it when | Gets | Writes |
| --- | --- | --- | --- | --- |
| 1 | `requirements-agent` | acceptance criteria are unknown, or `--from <KEY>` | ticket key or task text, output path | `requirements.md` |
| 2 | `architect-agent` | new component, new dependency, a boundary moves, or a structural refactor | `requirements.md` path, repo | `design.md` |
| 3 | `developer-agent` | production code changes | `design.md` (+ `requirements.md`) paths | `implementation.md` |
| 4 | `test-engineer-agent` | behaviour changed | `requirements.md` + `implementation.md` (+ `design.md` when stage 2 ran) paths | `tests.md` |
| 5 | `reviewer-agent` | any code change | diff range + `requirements.md`, `design.md` paths | `review.md` |
| 6 | `developer-agent` | review returned CRITICAL or MAJOR | the findings only | appends to `implementation.md` |
| 7 | `doc-writer-agent` | behaviour, architecture, config, API, or workflow changed, and not `--no-docs` | `implementation.md` (+ `design.md`) paths, diff range | reports files updated |

Typical rosters: business question → 1. Architecture question → 2. Refactor → 2, 3, 4, 5. New feature → 1–7. Documentation only → 7. Formatting only → none: run the
project formatter yourself.

Delegate to each agent as a foreground subagent, one at a time. Give it the
paths and the one-line task — never the previous agent's output pasted in, never the original
prompt when a brief has replaced it.

## Routing

- `BLOCKED: <business question>` → ask the **user**, then resume the same agent.
- `BLOCKED: <technical question>` from the developer or test engineer → re-invoke
  `architect-agent` with the question and `design.md`; it updates the design, then resume.
- `BLOCKED:` from the architect → the question is the requirements agent's or the user's. Never
  answer it yourself.
- A test failure goes back to whoever caused it: implementation → developer, structure →
  architect, ambiguous criterion → requirements or the user.
- Two failed rounds on the same finding → stop and report. Never let agents ping-pong.
- Never take a stage over because an agent was slow or wrong; re-invoke it with the correction.

`/deliver` ends with the change uncommitted and no branch — `change-delivery` §1 makes a dirty
tree a stop condition, so it cannot be handed to `/ticket-to-merge` afterwards. Take the ticket
route from the start when the work needs a branch, a commit and a merge request.

## Done when

Every criterion is met or explicitly waived by the user, the tests for the change pass, coverage
is met or its shortfall is justified, the reviewer's verdict is READY, and the documentation
stage has either run or been recorded as not needed. Compiling is not done.

Report: the roster you ran and why, the criteria and their status, files changed, test and
coverage result, the reviewer's verdict, the documentation outcome, and every open question. Say
which stages you skipped and why.

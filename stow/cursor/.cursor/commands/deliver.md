---
description: "Run a change through the specialised roles — only the ones the task needs"
---

Deliver the text after `/deliver` as a team of narrow agents. You are the orchestrator: you
route, you do not design, implement, test, or document. Prepares files only — no branch,
no commit.

## Workspace

`.claude/state/<slug>/` in the current repo, `<slug>` from the ticket key or a short task slug.
Create it. Every stage writes one file there; you pass **paths**, never file contents, and never
your own conversation, to the next agent. Existing files mean a resumed run: skip the stages that
already produced one unless the user asks for a redo.

## Sizing

Size the change before the first spawn — from the task text, or from `requirements.md` when
stage 1 ran. State the size and the roster before spawning.

**Small** only when all of these hold:

- one repository, one existing unit or its configuration;
- no new component, no new dependency, no boundary moved;
- no public API, schema, contract or migration touched;
- a handful of lines across one or two files;
- rollback is reverting the commit.

**Deep** when any of these hold (or you cannot answer): new component, new dependency, a
boundary moves, a structural refactor, or a public API, schema, contract or migration.

Everything else is **medium**.

| Size | Roster |
| --- | --- |
| Small | 3, then 4. Stage 5 only if the change is already documented somewhere. |
| Medium | 1 when criteria are unknown or `--from <KEY>`, then 3, then 4. Stage 5 only if the change is already documented somewhere. |
| Deep | 1, 2, then 3 and 4 in parallel off the stubs, then the join, then 5 unless `--no-docs`. |

No `design.md` on small or medium: the developer gets `requirements.md` or the task text, and
loads `design-patterns`.

Stage 4 drops out only when the diff has nothing to assert: every file in it is documentation,
formatter output, or configuration no runtime reads (editor, linter, CI). A dependency bump
qualifies when no call site changed and the existing suite is green. Anything the application
reads or executes at run time is not exempt, and neither is a diff you cannot classify — unclear
means stage 4 runs. Small is not a reason: a behaviour change of any size takes the test
engineer, and the developer never writes the tests in its place.

Escalate mid-run, running the skipped stages first, when the developer returns
`BLOCKED: <technical>`, the diff spreads past the files you sized, or a medium change grows a
deep trigger. Small → medium or deep; medium → deep. Report the re-size.

## Roster — invoke only what the task needs

| Stage | Agent | Run it when | Gets | Writes |
| --- | --- | --- | --- | --- |
| 1 | `requirements-agent` | medium/deep and criteria unknown, or `--from <KEY>` | ticket key or task text, output path | `requirements.md` |
| 2 | `architect-agent` | deep | `requirements.md` path, repo | `design.md` + the stubs it lists |
| 3 | `developer-agent` | production code changes | `design.md` when stage 2 ran, else `requirements.md` or the task text | `implementation.md` |
| 4 | `test-engineer-agent` | always, unless the diff is exempt under Sizing | deep: `requirements.md` + `design.md` + stub paths. Else `requirements.md` + `implementation.md` | `tests.md` |
| 5 | `doc-writer-agent` | deep (unless `--no-docs`), or medium/small when the change is already documented somewhere | `implementation.md` (+ `design.md`) paths, diff range | reports files updated |

Other rosters: business question → 1. Architecture question → 2. Documentation only → 5.
Formatting only → none: run the project formatter yourself.

Delegate to each agent as a foreground subagent, one at a time — the deep parallel pair below is
the only exception. Give it the paths and the one-line task — never the previous agent's output
pasted in, never the original prompt when a brief has replaced it.

## The parallel pair (deep)

The stubs are a frozen contract, so both agents can start from them at once — and the test
engineer never sees `implementation.md`, so it cannot mirror the implementation as assertions.

1. **Isolate.** `git worktree add --detach <path> HEAD` for the test engineer; the developer
   keeps the main tree, because two builds in one tree collide on the same output directory.
   Where that costs too much — a cold cache on a large build, a per-tree dependency install —
   run 3 then 4 sequentially and say you did. No safe isolation, no concurrency.
2. **Delegate to both** at once, each with its own paths and working directory.
3. **Collect** with `git -C <worktree> diff | git apply`, then `git worktree remove`. Test paths
   only, so the apply cannot conflict. No commit, no merge.
4. **Join.** Resume the test engineer with the `implementation.md` path: it runs the full suite
   and updates `tests.md` in place. Failures route as below.

## Advance gate

Every build-running stage reports its command and result in its own artifact. Do not advance
while that line is missing or red — re-invoke the same agent with the failure. A repository with
no build system for the touched files says so there, which is only acceptable when the files are
not code.

## Routing

- `BLOCKED: <business question>` → ask the **user**, then resume the same agent.
- `BLOCKED: <technical question>` from the developer or test engineer → re-invoke
  `architect-agent` with the question and `design.md`; it updates the design, then resume. If
  there is no design yet, that is a promote-to-deep.
- `BLOCKED:` from the architect → the question is the requirements agent's or the user's. Never
  answer it yourself.
- A test failure goes back to whoever caused it: implementation → developer, structure →
  architect, ambiguous criterion → requirements or the user.
- A test path in the developer's `git diff --name-only` is a fence breach — re-invoke it with
  the correction rather than keeping the edit.
- Two failed rounds on the same finding → stop and report. Never let agents ping-pong.
- Never take a stage over because an agent was slow or wrong; re-invoke it with the correction.

`/deliver` ends with the change uncommitted and no branch — `change-delivery` §1 makes a dirty
tree a stop condition, so it cannot be handed to `/ticket-to-merge` afterwards. Take the ticket
route from the start when the work needs a branch, a commit and a merge request.

## Done when

Every criterion is met or explicitly waived by the user, the tests for the change pass, coverage
is met or its shortfall is justified, and the documentation stage has either run or been
recorded as not needed. Compiling is not done.

Report: the roster you ran and why, the criteria and their status, files changed, test and
coverage result, the documentation outcome, and every open question. Say which stages you
skipped and why.

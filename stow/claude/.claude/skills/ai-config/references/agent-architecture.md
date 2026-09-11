# Agent architecture

Why the agent layer is shaped this way, and the bar a new agent has to clear. The operating
contract — report directory, schemas, questions, status, builds, commits, parallelism — is
`~/.claude/skills/agent-workflow/SKILL.md` and is not repeated here.

## The model

**Commands orchestrate. Agents specialise. Skills teach.**

A workflow is a command that invokes several narrow agents, each with one responsibility, the
smallest tool set that responsibility needs, and only the context its own step requires. It is
not one powerful agent carrying the whole task.

The failure this replaces: a single agent that read the ticket, chose the design, wrote the code,
wrote the tests, judged its own work and opened the merge request. Everything it read stayed in
one window — raw ticket JSON, knowledge-base pages, diffs, build logs — so the review stage
reasoned over the noise of the implementation stage, and the agent that wrote the test was the
one that wanted it to pass.

**Future compound workflows are orchestrated commands over specialised agents.** Not a bigger
agent. Departing from that needs a documented reason in this file.

## Agent rules

1. One primary responsibility, stated in the first line of the body.
2. Explicit **capabilities** (`tools:`) and explicit **limits** (`## Limits`). Every capability
   has a reason; every limit prevents a specific creep.
3. Only the context the responsibility needs: reports and paths, never the conversation that
   produced them.
4. The reports its own brief names, and nothing else. The architect additionally writes the
   stubs — the contract two later agents share.
5. No agent-to-agent calls. A blocked agent writes a question and returns `BLOCKED`; the
   orchestrator routes it. That makes circular delegation impossible rather than discouraged.
6. An agent that changes files builds and commits its own work; it never pushes and never
   rewrites history. A read-only agent produces a report and commits nothing.
7. An agent is reachable from at least one command from the day it is added.
8. Description in one or two lines: responsibility, inputs, outputs. Shared workflow rules live
   in `agent-workflow`, never restated per agent.
9. Every other named skill costs a file read on every spawn. Name `economy-of-words` only for an
   artifact no schema bounds — `doc-writer-agent` and nothing else today; the reports are bounded
   by `agent-workflow`'s schemas and the brevity floor is resident.

## Roles and their fences

| Agent | Owns | Must not |
| --- | --- | --- |
| `requirements-agent` | business intent, acceptance criteria | design, code, tests, commits |
| `architect-agent` | intended structure, decisions, compiling stubs, test boundaries | business decisions, behaviour, method bodies, test cases |
| `developer-agent` | production implementation | tests, design changes, documentation files when a doc writer is in the flow |
| `test-engineer-agent` | test strategy and tests | production code, criteria, design |
| `reviewer-agent` | the verdict | any change at all |
| `doc-writer-agent` | `/docs` and `README.md` | production source, tests, design or business decisions |

The fences matter more than the roles. Tests belong to someone who cannot edit the production
code, so a red test is reported rather than deleted. The verdict belongs to someone who never
read the implementer's reasoning, so the review judges the diff rather than re-deriving it.

Most fences are prose, because four agents hold unrestricted `Edit`/`Write` and `Bash`. The
reviewer's "no edits" fence is enforced by its `tools:` line, which omits `Edit`.

`/deliver` sizes the flow, and size never drops the test engineer — only a diff with no
behaviour to assert does. A flow that kept the developer and dropped its check would put the
author of the code back in charge of judging it, so the exemption removes the tests rather than
reassigning them.

## Parallelism

Agents cannot renegotiate mid-task and every spawn starts cold, so two may run at once **only**
against a contract frozen in a file both read before starting — the architect's stubs — and with
physically isolated trees. Missing either, run sequentially.

Splitting one role across several agents has neither: two developers share no frozen contract,
and the win is wall-clock rather than tokens or accuracy. Deliberately not done. The precondition
for revisiting it is disjoint file sets declared by the architect.

## Adding to this

**A new agent** needs all of: a bounded responsibility no existing agent covers, a measurable
reduction in context or improvement in accuracy, explicit capabilities and limits, and a command
that invokes it in the same change. Missing any one means it is not an agent.

- Knowledge several callers share → **a skill**. Duplicated mechanics went to `change-delivery`,
  the workflow contract to `agent-workflow`, Jira MCP calls to `jira-tickets`.
- A new way to sequence existing agents → **a command**.
- One more thing an existing role already owns → **that agent's file**.

No speculative agents, no agent per role for symmetry, no agent that only forwards to another.
There is deliberately **no formatter agent**: formatting is a build step, so it is a bounded
permission inside the agents that build — a subagent spawn would cost more than the command it
would run.

**Removing** an agent means removing its command references in both trees in the same change.

## Token efficiency

Judge a change by the tokens on the critical path, not by file count.

- Resident cost first: the router loads on every request, so a line there is the most expensive
  line in the repository.
- Per-stage cost: what an agent must read before it can act. A report beats a transcript; a path
  beats a paste; a `file:line` beats a diff hunk.
- Duplication costs twice — once for the copy, once when the copies drift and something has to
  reconcile them.
- A narrow agent that reads two files beats a broad one that reads twenty, even when the broad
  one needs fewer turns.

# Agent architecture

Why the agent layer is shaped this way, and the bar a new agent has to clear. Delivery agents
follow `agent-workflow`. Orchestrating commands follow `orchestration`. Neither is repeated here,
and neither is any agent's brief.

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
2. Explicit **capabilities** (`tools:`) and explicit **limits** (`## Limits`), in the agent's own
   brief and nowhere else — no agent reads another's. Every capability has a reason; every limit
   prevents a specific creep. Enforce a limit through `tools:` where it can be.
3. Only the context the responsibility needs: reports and paths, never the conversation that
   produced them. `$REPORTS` is open — list it and read what the task needs. Do not name
   required files in the brief.
4. It writes the reports its own brief names and nothing else, and that brief carries their
   schema: a schema belongs to its writer, never to the shared contract every agent loads.
   `research.md` is the exception; `agent-workflow` owns it.
5. No agent-to-agent calls and no questions between agents. An agent researches its own unknowns.
6. An agent that changes files builds and commits its own work; it never pushes and never
   rewrites history. A read-only agent produces a report and commits nothing.
7. An agent is reachable from at least one command from the day it is added.
8. Description in one or two lines: the responsibility and what it leaves behind. Shared
   workflow rules live in `agent-workflow`, never restated per agent; agent-specific rules never
   enter a shared skill.
9. Every other named skill costs a file read on every spawn. Name only what the responsibility
   needs, and load the conditional ones on their condition. Fence writes and harmful operations;
   do not fence research.

## Where the boundaries are, and why

Only independence justifies a boundary: `model:` cannot vary across the Claude–Cursor contract, so
no split pays for itself with a cheaper model.

- **Tests and implementation never share an agent.** The author of the code cannot be its
  independent check, so a change with nothing to assert drops the tests rather than reassigning
  them.
- **Criteria, design and contract are one agent.** A separate analyst researched what the prompt
  already answered, and a skippable architect left the tests with no contract. The context that
  settles a criterion is the context that shapes its signature.
- **Design and stubs stay together.** A separate stub writer was tried and reverted: `design.md`
  had to enumerate every signature for a second agent to transcribe.
- **Facts are not a service.** A research step, then questions routed between agents, each cost an
  orchestrator round trip for what a lookup answers.
- **Record-worthy decisions are the user's.** An implementer that wrote its own ADR turned a
  configuration tweak into architecture history. Agents propose; the user decides.

Routing is the orchestrator's, from the returned status alone: an agent narrow enough to be cheap
cannot see enough to route, and an agent that cannot call another cannot delegate in a circle.
Two agents never share a tree mid-task; revisiting that needs disjoint file sets declared up front.

## Adding to this

**A new agent** needs all of: a bounded responsibility no existing agent covers, a measurable
reduction in context or improvement in accuracy, explicit capabilities and limits, and a command
that invokes it in the same change. Missing any one means it is not an agent.

- Knowledge several callers share → **a skill**. Duplicated mechanics went to `change-delivery`,
  the agent contract to `agent-workflow`, command sequencing to `orchestration`, Jira MCP calls
  to `jira-tickets`.
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
  beats a paste; a `file:line` beats a diff hunk. Do not starve a stage of reports it needs.
- Duplication costs twice — once for the copy, once when the copies drift and something has to
  reconcile them.
- A narrow write fence beats a broad read fence: starve a stage of reports and accuracy drops.

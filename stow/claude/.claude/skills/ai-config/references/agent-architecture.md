# Agent architecture

How agents, commands and skills fit together here, and the rules a new one has to satisfy.
`SKILL.md` says which layer a rule belongs in; this file says how the agent layer is shaped.

## The model

**Commands orchestrate. Agents specialise. Skills teach.**

A workflow is a command that invokes several narrow agents in sequence, each with one
responsibility, the smallest tool set that responsibility needs, and only the context its own
step requires. It is not one powerful agent carrying the whole task.

The failure this replaces: a single agent that read the ticket, chose the design, wrote the code,
wrote the tests, judged its own work, committed and opened the merge request. Everything it read
stayed in one window — raw ticket JSON, knowledge-base pages, diffs, build logs — so the review
stage reasoned over the noise of the implementation stage, and the agent that wrote the test was
the one that wanted it to pass.

**Future compound workflows are orchestrated commands over specialised agents.** Not a bigger
agent. Departing from that needs a documented reason in this file.

## Agent rules

1. One primary responsibility, stated in the first line of the body.
2. Explicit **capabilities** (`tools:` frontmatter) and explicit **limits** (a `## Limits`
   section). Every capability has a reason; every limit prevents a specific creep.
3. Only the context the responsibility needs. An agent gets briefs and paths, never the
   conversation that produced them.
4. Exactly one output artifact, in a stated shape, written to a path the caller supplies.
5. No agent-to-agent calls. An agent that hits a wall returns `BLOCKED: <question>`; the command
   routes it. This is what makes circular delegation impossible rather than discouraged.
6. No agent commits, stages, branches or pushes. Git belongs to the command that carries the
   exception.
7. An agent is reachable from at least one command from the day it is added.
8. An agent's output template is where its brevity lives. `## Load first` costs a file read on
   every spawn, so name `economy-of-words` there only for an artifact no template bounds —
   `doc-writer-agent` and nothing else today.

## Roles and their fences

| Agent | Owns | Must not |
| --- | --- | --- |
| `requirements-agent` | business intent, acceptance criteria | design, code, tests, any write outside its brief |
| `architect-agent` | intended structure, plan, stubs | business decisions, behaviour, tests |
| `developer-agent` | production implementation | tests, design changes, docs, git |
| `test-engineer-agent` | test strategy and tests | production code, criteria, design |
| `reviewer-agent` | the verdict | any change at all |
| `doc-writer-agent` | documentation | code, tests, design or business decisions |

The fences matter more than the roles. Tests belong to someone who cannot edit the production
code, so a red test is reported rather than deleted. The verdict belongs to someone who never
read the implementer's reasoning, so the review judges the diff rather than re-deriving it.

## Hand-offs

Every stage writes one file into `.claude/state/<slug>/`; the command passes **paths**, not
contents. Both assistants use the same directory.

| Hand-off | Carries | Never carries |
| --- | --- | --- |
| requirements → architect | goal, criteria, constraints, open questions | ticket JSON, comment threads, knowledge-base prose |
| architect → developer | components, interfaces, dependencies, steps, relevant criteria | rejected alternatives, the requirements gathering |
| architect → test engineer | boundaries, intended behaviour, testability notes | implementation detail |
| developer → test engineer | changed components, seams, limitations | the design rationale, build logs |
| developer → reviewer | nothing — the reviewer reads the diff | the implementer's reasoning, on purpose |
| any → doc writer | what changed and why it matters | criteria history, review findings |
| reviewer → developer | the findings, located | the rest of the report |

Context that must never propagate: the original prompt once a brief replaces it, another
stage's tool output, an agent's chain of thought, and any criterion or file the receiving stage
does not act on.

## Escalation

| Ambiguity | Goes to |
| --- | --- |
| business | the user, via the command |
| technical, unresolvable from the repository | the architect, then the user |
| implementation detail | the architect |
| test fails — implementation wrong | the developer |
| test fails — design untestable | the architect |
| review finding | the developer |
| documentation contradicts behaviour | the architect, or requirements when it is a business fact |

Two failed rounds on the same finding stop the workflow. Nothing is resolved by an agent outside
its authority, and nothing is resolved by the orchestrator taking a stage over.

## Adding to this

**A new agent** needs all of: a bounded responsibility no existing agent covers, a measurable
reduction in context or improvement in accuracy, explicit capabilities and limits, a stated
communication boundary, and a command that invokes it in the same change. Missing any one of
those means it is not an agent.

- The need is knowledge several callers share → **a skill**. Duplicated mechanics between two
  commands went to `change-delivery`; duplicated Jira MCP calls went to `jira-tickets`.
- The need is a new way to sequence existing agents → **a command**.
- The need is one more thing an existing role already owns → **that agent's file**.

No speculative agents, no agent per role for symmetry, no agent that only forwards to another.
There is deliberately **no formatter agent**: formatting is a build step, so it is a bounded
permission inside the agents that build (`change-delivery` §4) — a subagent spawn would cost more
than the command it would run, and neither context nor accuracy improves.

**Removing** an agent means removing its command references in both trees in the same change.

## Token efficiency

Judge a change by the tokens on the critical path, not by file count.

- Resident cost first: the router loads on every request, so a line there is the most expensive
  line in the repository.
- Per-stage cost: what an agent must read before it can act. A brief beats a transcript; a path
  beats a paste; a `file:line` beats a diff hunk.
- Duplication is a token cost twice over — once for the copy and once when the two copies drift
  and something has to reconcile them.
- A narrow agent that reads two files beats a broad one that reads twenty, even when the broad
  one needs fewer turns.

---
name: ai-config
description: "Authoring and changing this machine's AI assistant configuration: where a rule belongs across router / command / agent / skill, the Claude–Cursor sharing contract and its parity guard, frontmatter shapes, git hooks, MCP server registration for both assistants, and the machine-local overlay. Use when adding or editing a skill, agent, command, rule, or MCP server under stow/claude or stow/cursor."
argument-hint: "What is being added or changed (e.g. 'add a skill for X', 'command keeps duplicating the agent', 'does Cursor see this')"
---

# AI assistant configuration

Source of truth: `stow/claude/.claude/` and `stow/cursor/.cursor/` in the dotfiles repo. Design
rationale lives in `docs/ARCHITECTURE.md` → *AI assistant configuration*; this skill is how to
change it without breaking the contract.

**Detail lives in `references/`** — read the file the task needs, not both.

- `references/frontmatter.md` — skill, agent, command, and Cursor-rule frontmatter, plus
  `alwaysApply` / `globs` / `description` load modes.
- `references/mcp-and-hooks.md` — MCP registration for both assistants, the server list, and
  the git hooks under `stow/git`.
- `references/agent-architecture.md` — the agent model. Read it before adding or changing any
  agent.

---

## Which layer does it belong in

Layers, no overlap. Getting this wrong is the defect that keeps recurring — content gets
restated in two places, they drift, and the assistant follows whichever it read last.

| Layer | Owns | Loaded |
| --- | --- | --- |
| **Router** — `CLAUDE.md` (Claude only) | Mapping situation → skill, plus the cross-cutting prohibitions (git, documentation, machine-local). | Every Claude request |
| **Cursor rules** — `rules/*.mdc` | Always-on contracts; optional `globs` when a file type should nag a skill. | `alwaysApply` or matching files |
| **Command** — `commands/<name>.md` | Argument parsing, dispatch, relaying output | On invocation |
| **Agent** — `agents/<name>-agent.md` | One responsibility, its tools, its output artifact, its limits | When spawned |
| **Skill** — `skills/<name>/SKILL.md` | Domain knowledge, and any MCP server it fronts | On demand |

Decide with these questions, in order:

1. **Is it knowledge that is true regardless of who asks?** → skill.
2. **Is it one bounded responsibility with its own output artifact?** → agent — see
   `references/agent-architecture.md` for the bar it has to clear.
3. **Is it how to sequence agents, or how to start one?** → command.
4. **Does it change what to load in a situation?** → one `CLAUDE.md` table row. Cursor picks
   skills from each skill's `description`, so add a `.mdc` only to scope a skill to a file type
   (`globs`) or to carry a contract that must hold before the skill is read.

On Claude Code the router (`CLAUDE.md`) is the only file resident on every request. Adding
prose there costs tokens on work that will never use it. It routes; it does not teach.

On Cursor, rules are standing contracts (`alwaysApply`) or file-scoped nags (`globs`). Never
copy the `CLAUDE.md` table into a rule, and never add an always-on rule whose only content is
"load skill X" — the skills catalog already does that.

### Command shapes

Three, and a command is exactly one of them:

- **Dispatcher** — one agent owns the job. `/create-tech-ticket`, `/enhance-jira-description`,
  `/dotfiles-devops`: spawn it, relay unabridged, resume the **same** agent via SendMessage
  rather than spawning a second one.
- **Orchestrator** — several narrow agents in sequence, with the stage conditions, the hand-off
  paths and the escalation routing. `/deliver` (three sizes), `/ticket-to-merge`, `/mr-review`,
  `/bug-fix`.
  It routes; it never does a stage itself.
- **Policy** — the decision *is* the command and has no other consumer, and the work is
  mechanical. `/sonar-fix`: its fix/skip list is the whole point, so it edits directly.

All three take external data from a skill and never touch an MCP server the skill owns
(`sonarqube-validation`, `app-bug-detection`, `jira-tickets`), and shared mechanics from
`change-delivery` instead of restating them. An orchestrator that starts explaining *how* a
stage works has taken over an agent's layer.

---

## The sharing contract

Skills and agents are authored **once**, under `stow/claude/.claude/`. Cursor discovers
`~/.claude/skills/` and `~/.claude/agents/` natively.

**Never create `skills/` or `agents/` under `stow/cursor/.cursor/`.** A same-named file there
takes precedence and shadows the shared original — and the failure is silent, because the
assistant still finds *a* skill. `check-ai-parity.sh` fails the build on this, and `stow.sh` runs
it before stowing anything.

Only three things are legitimately Cursor-specific:

- `rules/*.mdc` — Cursor needs `.mdc` frontmatter. One concern per file: always-on contracts
  (`git`, `documentation`, `layers`, `economy-of-words`), or `globs` when a file type should pull
  in a skill (`java`, `neovim`). An always-on rule states its contract; it never exists only to
  redirect.
- `commands/*.md` — Cursor has no `$ARGUMENTS`, so the wording differs; the logic must not
  drift.
- `mcp.json` — same server list, `${env:VAR}` instead of `${VAR}`

When you change a command, change both copies in the same edit. When you add or rename a skill,
add a `CLAUDE.md` table row; Cursor uses the skill `description` with no extra `.mdc`. The
always-on rules that mirror a `CLAUDE.md` section — `git`, `documentation`, `layers`,
`economy-of-words` — must stay in step with it. That is the only intentional duplication, and
the only place drift can still start.

---

## Size and progressive disclosure

Every file here is prose that lands in a context window, so `economy-of-words` is the writing
standard — load it before authoring one.

A `SKILL.md` over roughly 200 lines is doing two jobs. Split the long tail into
`references/<topic>.md` and link to it from the body — the reference is read only when the task
actually needs that depth. Existing splits to copy: `dotfiles`, `stow`, `grafana`,
`bitwarden-cli`.

A section written for a **different agent** than the rest of the skill belongs in its own
reference, however short — `java-standards/references/tests.md` is read by the test engineer,
examples by the developer. Splitting by audience keeps each spawn to what it can act on; a new
skill for a section that small would only add a second owner of the same domain.

Templates and scaffolds go in `assets/` (see `atdd/assets/feature.template`).

---

## Machine-local overlay

Anything organisation-specific — project keys, board and sprint ids, documentation repositories,
cluster and namespace names — lives in `~/.claude/local/*.md`, restored from Bitwarden and never
tracked. `~/.cursor/local` is a symlink to the same directory.

Skills and agents **name the file to read**; they never inline its contents:

> Read `~/.claude/local/jira-conventions.md` before drafting. If it is missing, ask rather than
> guessing.

The dotfiles repo is public — see its project `CLAUDE.md`. A value that identifies the
organisation or its network must not enter a tracked file, including as an example.

---

## Before finishing a change

1. `bash check-ai-parity.sh` — no skills or agents leaked into the cursor tree.
2. `bash stow.sh -n` — dry run; the guard runs first and conflicts surface here.
3. Did a command change? Update both copies. Did a skill mapping change? `CLAUDE.md` table row
   only. Did a rule mirroring a `CLAUDE.md` section change (`git`, `documentation`, `layers`)?
   Both copies.
4. Added or changed an agent? It must be invoked by a command in the same change, and its
   capabilities, limits and hand-off must match `references/agent-architecture.md`. Removed one?
   Remove every reference in both trees.
5. Did structure, bootstrap flow, or the package list change? Update `README.md` **and**
   `docs/ARCHITECTURE.md` — they have drifted from each other before.
6. Releasing? Use `/release` — it bumps `VERSION`, the badge, and the changelog together.

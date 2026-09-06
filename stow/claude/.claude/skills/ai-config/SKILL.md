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

- `references/frontmatter.md` — the exact frontmatter for a skill, agent, command, and Cursor
  rule, plus the table of `alwaysApply` / `globs` / `description` load modes.
- `references/mcp-and-hooks.md` — registering an MCP server for both assistants, the server
  list, and the git hooks under `stow/git`.

---

## Which layer does it belong in

Layers, no overlap. Getting this wrong is the defect that keeps recurring — content gets
restated in two places, they drift, and the assistant follows whichever it read last.

| Layer | Owns | Loaded |
| --- | --- | --- |
| **Router** — `CLAUDE.md` (Claude only) | Mapping situation → skill, plus the cross-cutting prohibitions (git, documentation, machine-local). | Every Claude request |
| **Cursor rules** — `rules/*.mdc` | Always-on contracts; optional `globs` when a file type should nag a skill. | `alwaysApply` or matching files |
| **Command** — `commands/<name>.md` | Argument parsing, dispatch, relaying output | On invocation |
| **Agent** — `agents/<name>-agent.md` | Workflow, output format, constraints | When spawned |
| **Skill** — `skills/<name>/SKILL.md` | Domain knowledge, and any MCP server it fronts | On demand |

Decide with these questions, in order:

1. **Is it knowledge that is true regardless of who asks?** → skill.
2. **Is it a repeatable multi-step workflow with its own output format?** → agent.
3. **Is it only "how do I start that workflow"?** → command, and keep it to dispatch.
4. **Does it change what to load in a situation?** → one `CLAUDE.md` table row. Cursor picks
   skills from each skill's `description`, so add a `.mdc` only to scope a skill to a file type
   (`globs`) or to carry a contract that must hold before the skill is read.

On Claude Code the router (`CLAUDE.md`) is the only file resident on every request. Adding
prose there costs tokens on work that will never use it. It routes; it does not teach.

On Cursor, rules are standing contracts (`alwaysApply`) or file-scoped nags (`globs`). Never
copy the `CLAUDE.md` table into a rule, and never add an always-on rule whose only content is
"load skill X" — the skills catalog already does that.

### The two exceptions

`/sonar-fix` and `/bug-fix` own their steps inline, because the fix policy *is* the command and
has no other consumer. They still delegate all external data to a skill
(`sonarqube-validation`, `app-bug-detection`) and never touch those MCP servers directly. Every
other command is a dispatcher — spawn `<command>-agent`, relay unabridged, resume the **same**
agent via SendMessage rather than spawning a second one.

---

## The sharing contract

Skills and agents are authored **once**, under `stow/claude/.claude/`. Cursor discovers
`~/.claude/skills/` and `~/.claude/agents/` natively.

**Never create `skills/` or `agents/` under `stow/cursor/.cursor/.`** A same-named file there
takes precedence and shadows the shared original — and the failure is silent, because the
assistant still finds *a* skill. `check-ai-parity.sh` fails the build on this, and `stow.sh` runs
it before stowing anything.

Only three things are legitimately Cursor-specific:

- `rules/*.mdc` — Cursor needs `.mdc` frontmatter. One concern per file: always-on contracts
  (`git`, `documentation`, `layers`, `economy-of-words`), or `globs` when a file type should pull
  in a skill (`java`, `neovim`). An always-on rule states its contract; it never exists only to
  redirect.
- `commands/*.md` — Cursor has no `$ARGUMENTS`, so the wording differs; the logic must not
- `mcp.json` — same server list, `${env:VAR}` instead of `${VAR}`

When you change a command, change both copies in the same edit. When you add or rename a skill,
add a `CLAUDE.md` table row; Cursor uses the skill `description` with no extra `.mdc`. The
always-on rules that mirror a `CLAUDE.md` section — `git`, `documentation`, `layers`,
`economy-of-words` — must
stay in step with it. That is the only intentional duplication, and the only place drift
can still start.

---

## Size and progressive disclosure

A `SKILL.md` over roughly 200 lines is doing two jobs. Split the long tail into
`references/<topic>.md` and link to it from the body — the reference is read only when the task
actually needs that depth. Existing splits to copy: `dotfiles`, `stow`, `grafana`,
`bitwarden-cli`.

Templates and scaffolds go in `assets/` (see `atdd-java/assets/feature.template`).

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
4. Did structure, bootstrap flow, or the package list change? Update `README.md` **and**
   `docs/ARCHITECTURE.md` — they have drifted from each other before.
5. Releasing? Use `/release` — it bumps `VERSION`, the badge, and the changelog together.

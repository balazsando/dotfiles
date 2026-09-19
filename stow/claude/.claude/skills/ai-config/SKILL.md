---
name: ai-config
description: "Authoring and changing this machine's AI assistant configuration: where a rule belongs across router / command / agent / skill, the Claude–Cursor sharing contract and its parity guard, frontmatter shapes, git hooks, MCP server registration for both assistants, and the machine-local overlay. Use when adding or editing a skill, agent, command, rule, or MCP server under stow/claude or stow/cursor."
argument-hint: "What is being added or changed (e.g. 'add a skill for X', 'does Cursor see this')"
---

# AI assistant configuration

Source of truth: `stow/claude/.claude/` and `stow/cursor/.cursor/` in the dotfiles repo.

Read the reference the task needs:

- `references/frontmatter.md` — skill, agent, command, and Cursor-rule frontmatter, and the rule
  load modes.
- `references/mcp-and-hooks.md` — MCP registration for both assistants, the server list, and
  the git hooks under `stow/git`.

---

## Which layer does it belong in

Layers, no overlap. Content restated in two places drifts, and the assistant follows whichever it
read last.

| Layer | Owns | Loaded |
| --- | --- | --- |
| **Router** — `CLAUDE.md` (Claude only) | Situation → skill, plus the standing contracts (git, documentation, communication, implementation, machine-local) | Every Claude request |
| **Cursor rules** — `rules/*.mdc` | The same standing contracts; `globs` rules that pull in a skill for a file type | `alwaysApply` or matching files |
| **Command** — `commands/<name>.md` | Arguments, policy, and steps of one workflow | On invocation |
| **Agent** — `agents/<name>-agent.md` | One bounded responsibility, its `tools:` fence, its limits | When a command spawns it |
| **Skill** — `skills/<name>/SKILL.md` | Domain knowledge, and any MCP server it fronts | On demand |

1. **Knowledge that is true regardless of who asks?** → skill.
2. **A workflow the user starts by name?** → command.
3. **Work that needs its own context window or tool fence?** → agent, spawned by a command in the
   same change. None are authored here: multi-agent orchestration cost more than it saved, so add
   one only against a measured gain.
4. **Changes what to load in a situation?** → one `CLAUDE.md` table row. Cursor picks skills
   from their `description`, so add a `.mdc` only to scope a skill to a file type (`globs`).

A standing contract earns a resident slot only if it changes behaviour on turns where no skill
would load — prohibitions and defaults, not reference knowledge. Every router line costs tokens on
every request. Never copy the routing table into a Cursor rule, and never add an always-on rule
whose only content is "load skill X".

What earns a line anywhere: house preferences (formatting, naming, architecture, tooling
choices) and knowledge the model would otherwise get wrong. Not textbook content it already
knows, not a restated contract, and not a way of working — the only process forced on every
turn is YAGNI, accuracy, and token efficiency, in that order. When two layers say the same
thing, delete it from the on-demand one.

A command takes external data from the skill that owns it (`sonarqube-validation`,
`app-bug-detection`, `jira-tickets`), never from the MCP server directly, and branch, build and
commit mechanics from `change-delivery`. A command explaining *how* a domain works has taken over
a skill's layer.

---

## The sharing contract

Skills and agents are authored **once**, under `stow/claude/.claude/`. Cursor discovers
`~/.claude/skills/` and `~/.claude/agents/` natively.

**Never create `skills/` or `agents/` under `stow/cursor/.cursor/`.** A same-named copy there
shadows the shared original silently. `check-ai-parity.sh` fails on it, and `stow.sh` runs it
first.

Cursor-specific, and nothing else:

- `rules/*.mdc` — one concern per file. Always-on rules mirror a `CLAUDE.md` section: `git`,
  `documentation`, `layers` (precedence, machine-local), `economy-of-words`,
  `economy-of-implementation`. `globs` rules: `java`, `neovim`.
- `commands/*.md` — no `argument-hint`, no arguments placeholder ("the text after
  `/<command>`" instead), and `~/.cursor/local/` paths; otherwise identical to the Claude copy.
- `mcp.json` — same server list, `${env:VAR}` instead of `${VAR}`.

Mirrored rules and command twins are the only intentional duplication. Change both copies in the
same edit.

---

## Size

A `SKILL.md` over roughly 200 lines is doing two jobs. Move the long tail to
`references/<topic>.md` and link it from the body (see `dotfiles`, `micrometer`,
`bitwarden-cli`). Templates and scaffolds go in `assets/` (see `atdd/assets/feature.template`).

---

## Machine-local overlay

Organisation-specific values — project keys, board and sprint ids, documentation repositories,
cluster names — live in `~/.claude/local/*.md`, restored from Bitwarden, never tracked.
`~/.cursor/local` symlinks to it. Skills and commands name the file and say what to do when it is
missing; they never inline its contents. The dotfiles repo is public — see its project
`CLAUDE.md`.

---

## Before finishing a change

1. `bash check-ai-parity.sh`, then `bash stow.sh -n`.
2. Command or mirrored rule changed → both copies. Skill added or renamed → `CLAUDE.md` table
   row. Agent added → the command that spawns it. Something removed → every reference in both
   trees.
3. Structure, bootstrap flow, or package list changed → `README.md`.
4. Releasing → `/release`.

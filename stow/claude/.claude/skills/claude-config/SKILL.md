---
name: claude-config
description: "Authoring and changing this machine's AI assistant configuration: where a rule belongs across router / command / agent / skill, the Claude–Cursor sharing contract and its parity guard, frontmatter shapes, git hooks, and the machine-local overlay. Use when adding or editing a skill, agent, command, or rule under stow/claude or stow/cursor."
argument-hint: "What is being added or changed (e.g. 'add a skill for X', 'command keeps duplicating the agent', 'does Cursor see this')"
---

# AI assistant configuration

Source of truth: `stow/claude/.claude/` and `stow/cursor/.cursor/` in the dotfiles repo. Design
rationale lives in `docs/ARCHITECTURE.md` → *AI assistant configuration*; this skill is how to
change it without breaking the contract.

---

## Which layer does it belong in

Four layers, no overlap. Getting this wrong is the defect that keeps recurring — content gets
restated in two places, they drift, and the assistant follows whichever it read last.

| Layer | Owns | Loaded |
| --- | --- | --- |
| **Router** — `CLAUDE.md`, `global-instructions.mdc` | Mapping situation → skill. Cross-cutting prohibitions. | Every request |
| **Command** — `commands/<name>.md` | Argument parsing, dispatch, relaying output | On invocation |
| **Agent** — `agents/<name>-agent.md` | Workflow, output format, constraints | When spawned |
| **Skill** — `skills/<name>/SKILL.md` | Domain knowledge, and any MCP server it fronts | On demand |

Decide with these questions, in order:

1. **Is it knowledge that is true regardless of who asks?** → skill.
2. **Is it a repeatable multi-step workflow with its own output format?** → agent.
3. **Is it only "how do I start that workflow"?** → command, and keep it to dispatch.
4. **Does it change what to load in a situation?** → one router table row, nothing more.

The router is the only file resident on every request. Adding prose there costs tokens on work
that will never use it. It routes; it does not teach.

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

- `rules/global-instructions.mdc` — Cursor needs `.mdc` frontmatter; mirrors the router contract
- `commands/*.md` — Cursor has no `$ARGUMENTS`, so the wording differs; the logic must not
- `mcp.json` — same server list, `${env:VAR}` instead of `${VAR}`

When you change a router rule or a command, change both copies in the same edit. They are the
only intentional duplication in the tree, and the only place drift can still start.

---

## Frontmatter

**Skill** — `skills/<name>/SKILL.md`:
```yaml
---
name: kebab-case-name          # must match the directory name
description: "When to load this, in trigger terms — this is what routing matches on"
argument-hint: "what the caller should supply"
---
```

**Agent** — `agents/<name>-agent.md`:
```yaml
---
name: <name>-agent             # must match the filename
description: "What it does and when to use it"
---
```

**Command** — `commands/<name>.md`:
```yaml
---
description: "One line, shown in the command list"
argument-hint: "[--flag <v>] <required>"
---
```

**Cursor rule** — `rules/<name>.mdc`:
```yaml
---
description: What this rule governs
alwaysApply: true              # false = model-selected by description
---
```

The skill `description` is the routing signal — write it as the situation that should trigger it,
not as a summary of the contents. Nothing reads a skill's prose to decide whether to load it.

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

## Hooks

Git hooks are stowed from `stow/git/.githooks/` and enabled globally by `core.hooksPath`, so they
run in **every** repository on the machine — a new hook must be safe in a work repo, not just
this one. `prepare-commit-msg` expands `category-message` into the final subject and strips
tooling attribution.

Write them in POSIX `sh`: `shopt` and other bash-only builtins fail there, and a `.sh` extension
does not make a file bash. Keep them fast — a slow or noisy hook gets bypassed reflexively, which
is worse than no hook.

Claude Code's own hooks would live in `~/.claude/settings.json`, which is **deliberately not
tracked**: it holds machine- and repo-specific context that must not be published. Do not stow,
copy, or quote it here.

---

## Before finishing a change

1. `bash check-ai-parity.sh` — no skills or agents leaked into the cursor tree.
2. `bash stow.sh -n` — dry run; the guard runs first and conflicts surface here.
3. Did a router rule or command change? Update both the Claude and Cursor copy.
4. Did structure, bootstrap flow, or the package list change? Update `README.md` **and**
   `docs/ARCHITECTURE.md` — they have drifted from each other before.
5. Releasing? Use `/release` — it bumps `VERSION`, the badge, and the changelog together.

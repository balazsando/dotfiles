# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and [mise](https://mise.jdx.dev/).  
Targeting **Debian/Ubuntu/WSL2**.

[![Version](https://img.shields.io/badge/version-1.4.0-blue)](CHANGELOG.md)

---

## Repository layout

```
dotfiles/
├── stow/                   # GNU Stow packages (each maps to $HOME)
│   ├── bat/                # bat syntax-highlighter config + themes
│   ├── bin/                # Standalone binaries
│   ├── claude/             # Claude Code: CLAUDE.md, agents, commands, skills, MCP
│   ├── cursor/             # Cursor: rules, commands, MCP (skills/agents shared from claude/)
│   ├── git/                # .gitconfig, .githooks, .config/git/{ignore,credentials}
│   ├── java/               # Maven settings, Eclipse formatter
│   ├── lf/                 # lf file manager config
│   ├── mise/               # .mise.toml — all runtimes and CLI tools
│   ├── nvim/               # LazyVim / Neovim config
│   ├── posting/            # Posting HTTP client config
│   ├── scripts/            # Operational scripts → ~/.local/share/dotfiles/scripts/
│   ├── tmux/               # tmux config
│   └── zsh/                # .zshrc, .p10k.zsh, ~/.config/zsh/ fragments
├── host/                   # Machine-specific config (copied, never symlinked)
│   ├── wsl.conf            # Applied to /etc/wsl.conf on WSL2 machines
│   └── work-wsl/           # Work-machine WSL overrides
├── packages/
│   ├── apt.txt             # System-level APT packages
│   ├── pip.txt             # pip packages (if any)
│   └── uv-tools.txt        # Python CLI tools installed as isolated uv tools
├── docs/
│   └── ARCHITECTURE.md     # Design decisions and rationale
├── CLAUDE.md               # Project rules — never publish secrets (.cursor/rules/ mirrors it)
├── .claude/commands/       # Project commands: /release (.cursor/commands/ mirrors them)
├── install.sh              # Bootstrap entry point — run once on a new machine
├── stow.sh                 # Idempotent re-stow — safe to run at any time
├── check-ai-parity.sh      # Guard: no skills/agents under stow/cursor (they shadow the shared ones)
└── sync.sh                 # Pre-migration export (wsl.conf, repos, BW secrets)
```

### AI assistant configs (claude/ + cursor/)

Skills and agents are authored **once** in `stow/claude/.claude/` and consumed by both
assistants: Cursor natively discovers `~/.claude/skills/` and `~/.claude/agents/`
([compatibility paths](https://cursor.com/docs/skills)). Never add `skills/` or `agents/`
under `stow/cursor/` — a same-named copy there takes precedence and shadows the shared
original. `stow.sh` runs `check-ai-parity.sh` to enforce this.

Agents are **roles**, not pipelines: `requirements`, `architect`, `developer`, `test-engineer`,
`reviewer` and `doc-writer` each own one responsibility, declare the tools they may use, and
write one brief into `.claude/state/<slug>/`. Commands sequence them and own git — `/deliver`
(pick the roles the task needs), `/ticket-to-merge` (Jira → merge request), `/mr-review`,
`/bug-fix`, `/sonar-fix`. No agent commits, and no agent calls another: a blocked agent hands
the question back to the command. The model and the bar for adding a new agent are in
`~/.claude/skills/ai-config/references/agent-architecture.md`.

The cursor package keeps only what is genuinely platform-specific:

- `rules/*.mdc` — one concern per file (Cursor needs `.mdc` frontmatter): always-on contracts
  (`git`, `documentation`, `layers`, `economy-of-words`, `graphify`), and `globs` rules that pull in a skill
  for a file type (`java`, `neovim`)
- `commands/*.md` — thin dispatchers (Cursor has no `$ARGUMENTS`; agents do the work)
- `mcp.json` — same server list as `mcp-servers.json`, Cursor's `${env:VAR}` syntax

Machine-local files (Jira conventions, doc repos, k8s environments) live once in
`~/.claude/local/`; `~/.cursor/local` is a symlink to it, so both assistants read the same
unversioned files.

### Agent token tooling (rtk + graphify)

Both cut what the agents *read*. Neither wraps the agent process:
[rtk](https://github.com/rtk-ai/rtk) is a `PreToolUse` hook that rewrites bash calls
(`git status` → `rtk git status`), and [graphify](https://github.com/Graphify-Labs/graphify)
is a skill that answers codebase questions from a graph instead of a grep. The `claude` and
`ai` shell functions register the hook for their agent if it is missing, then launch it.

rtk comes from `.mise.toml`, graphify from `packages/uv-tools.txt` (PyPI `graphifyy`). Both
register into `~/.claude/{settings.json,skills/}` — live runtime state, so registration goes
through their CLIs rather than stow: the skill in `install.sh` step 11c, the hook lazily on
first launch. rtk rewrites only the **Bash** tool; `Read`/`Grep`/`Glob` bypass it. `rtk gain`
shows the savings.

The code graph builds itself. `stow/git/.githooks/post-commit` runs `graphify update` after
every commit in every repo — an AST-only rebuild that is local, deterministic and costs no
tokens. It is detached, so it never delays a commit; `GRAPHIFY_DISABLE_HOOK=1` opts out.

Do **not** run `graphify hook install`: it writes `.git/hooks/post-commit`, which git ignores
here because `core.hooksPath` points at `~/.githooks`.

Only the semantic pass over docs, PDFs and images needs the agent — run `/graphify .` when you
want those in the graph too. `graphify claude install` adds an always-on nudge to one repo; soft
mode (nudge toward `graphify query`) is the default, pinned by `GRAPHIFY_HOOK_STRICT=0` in
`env.zsh`, and `--strict` blocks the first raw file read of a session instead.

### Keeping secrets out of the repository

This repository is public and configures a machine that works against private infrastructure,
so nothing organisation-specific may enter a tracked file. Values live in
`~/.config/zsh/secrets` or `~/.claude/local/`; tracked files reference them by name. The rule
and what counts as sensitive are in `CLAUDE.md`, mirrored for Cursor in `.cursor/rules/`.

---

## Quick start

```bash
git clone https://github.com/balazsando/dotfiles ~/dotfiles
cd ~/dotfiles
bash install.sh
exec zsh
```

---

## What `install.sh` does

| Step | Description |
|------|-------------|
| **1. APT packages** | System deps from `packages/apt.txt` (includes `npm` for early BW install) |
| **2. WSL PATH guard** | Detects Windows PATH contamination; applies `host/wsl.conf` and exits for restart if needed |
| **3. BW CLI** | Installs `@bitwarden/cli` via npm — must precede mise to fetch VPN certs |
| **4. Secrets + certs** | Restores `~/.config/zsh/secrets`, `~/.config/git/credentials`, kube configs, and `~/certs/` from Bitwarden; updates system CA store |
| **5. Oh-My-Zsh** | Installs OMZ + `zsh-autosuggestions`, `zsh-syntax-highlighting`, Powerlevel10k |
| **6. GitHub binaries** | Fetches `jirlab`, pinned to a commit and SHA256-verified |
| **6b. cursor-agent** | Installs cursor-agent from Cursor's official installer |
| **7. Default shell** | Sets zsh as the login shell via `chsh` |
| **8. mise + tools** | Installs mise, then provisions all runtimes and CLI tools from `.mise.toml` |
| **9. GNU Stow** | Symlinks all packages from `stow/` into `$HOME` |
| **10. tmux TPM** | Clones Tmux Plugin Manager |
| **11. Git identity** | Writes `~/.gitconfig_local` from BW secrets or interactive prompt |
| **11b. MCP servers** | Registers MCP servers into `~/.claude.json` via the `claude` CLI |
| **11c. Agent token tooling** | Installs uv tools from `packages/uv-tools.txt` and registers the `graphify` skill (the `rtk` hook is registered on first agent launch) |
| **12. Post-install** | Imports Java certs (with per-cert confirmation), syncs Neovim plugins, installs tmux plugins, restores repos |

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the rationale behind the step ordering.

---

## Day-to-day usage

```bash
bash stow.sh           # re-stow after adding/moving dotfiles
mise run stow          # same via mise task
mise run sync          # git pull + restow
mise run update-tools  # upgrade all mise-managed tools
```

---

## Bitwarden secrets

All sensitive files are stored as Bitwarden secure notes under the `dotfiles/` prefix.

| BW item | Destination |
|---|---|
| `dotfiles/zsh_secrets` | `~/.config/zsh/secrets` |
| `dotfiles/git-credentials` | `~/.config/git/credentials` |
| `dotfiles/kube/<filename>` | `~/.kube/<filename>` |
| `dotfiles/certs/<filename>` | `~/certs/<filename>` |
| `dotfiles/repos` | `$DOTFILES/repos.txt` |
| `dotfiles/ai/<filename>` | `~/.claude/local/` (`~/.cursor/local` symlinks to it) |

```bash
# Restore secrets manually
bash ~/.local/share/dotfiles/scripts/bw-restore.sh

# Upload before migrating
zsh ~/.local/share/dotfiles/scripts/bw-upload.zsh
```

`bw-restore.sh` and `bw-upload.zsh` are the **only** two Bitwarden entry points — nothing else
talks to the vault.

Machine-specific values that would otherwise identify internal infrastructure
(`JIRA_*` ids and workflow names, `NEXUS_SERVER_ID`, `WORK_K8S_*`, `WIN_USER`, and the
kubeconfig-switching aliases) live in `~/.config/zsh/secrets` and are consumed as
variables by the tracked config. The AI overlay
(`dotfiles/ai/*`) carries the equivalent context for skills and agents as markdown, since
markdown has no variable expansion.

---

## Git identity

User name and email are stored in `~/.gitconfig_local` (not versioned) and included by `.gitconfig` at runtime.

```bash
git config --file ~/.gitconfig_local user.name  "Your Name"
git config --file ~/.gitconfig_local user.email "you@example.com"
```

---

## Adding new dotfiles

1. Create `stow/<package-name>/` mirroring the target path from `$HOME`.
2. Place config files inside.
3. Run `bash stow.sh` — auto-discovery handles the rest.


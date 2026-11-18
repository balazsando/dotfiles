# dotfiles

Personal dotfiles for Debian/Ubuntu/WSL2, managed with
[GNU Stow](https://www.gnu.org/software/stow/) and [mise](https://mise.jdx.dev/).

[![Version](https://img.shields.io/badge/version-2.3.0-blue)](CHANGELOG.md)

The repository is public. What may enter a tracked file is ruled by `CLAUDE.md`, mirrored for
Cursor in `.cursor/rules/no-leaks.mdc`.

## Layout

```
dotfiles/
├── stow/                   # GNU Stow packages — each maps to $HOME
│   ├── bat/                # bat config + themes
│   ├── bin/                # Standalone tools: mdview, plantuml, pumlview (text previews)
│   ├── claude/             # Claude Code: CLAUDE.md, commands, skills, MCP
│   ├── cursor/             # Cursor: rules, commands, MCP (skills/agents shared from claude/)
│   ├── git/                # .gitconfig, .githooks, .config/git/ignore
│   ├── glab-tui/           # glab-tui config (Catppuccin Mocha preset)
│   ├── glow/               # glow theme (selected by GLOW_STYLE)
│   ├── java/               # Maven settings, Eclipse formatter
│   ├── k9s/                # k9s skin (selected by K9S_SKIN)
│   ├── lazygit/            # lazygit config (open the most recent repository)
│   ├── lf/                 # lf file manager
│   ├── mise/               # .mise.toml — runtimes, CLI tools, tasks
│   ├── nvim/               # LazyVim
│   ├── ponytail/           # ponytail default level (Claude + Cursor hooks)
│   ├── posting/            # Posting HTTP client
│   ├── scripts/            # Operational scripts → ~/.local/share/dotfiles/scripts/
│   ├── tmux/               # tmux
│   └── zsh/                # .zshrc, .p10k.zsh, ~/.config/zsh/ fragments
├── host/                   # Machine-specific config — copied, never symlinked
│   ├── wsl.conf            # → /etc/wsl.conf on WSL2
│   └── work-wsl/           # Work-machine WSL overrides
├── cheatsheets/            # Personal reference notes (Markdown), not stowed
├── packages/
│   ├── apt.txt             # APT packages
│   └── uv-tools.txt        # Python CLI tools installed as uv tools
├── .claude/commands/       # /release, /review-staged (mirrored in .cursor/commands/)
├── CLAUDE.md               # Project rules — never publish secrets
├── install.sh              # Bootstrap — run once on a new machine
├── stow.sh                 # Idempotent re-stow
├── check-ai-parity.sh      # Guard: no skills/agents under stow/cursor
├── sync.sh                 # Pre-migration export (wsl.conf, repos, BW secrets)
├── CHANGELOG.md            # Keep a Changelog, SemVer
├── VERSION                 # Current version, mirrored by the badge above
└── repos.txt               # Repo manifest — gitignored, restored from Bitwarden
```

Scripts resolve the repository through `$DOTFILES` (exported by `install.sh`, default
`~/dotfiles`).

## Load-bearing decisions

Do not "fix" these.

**Stow**

- `stow.sh` discovers packages with `find -maxdepth 1 -mindepth 1 -type d`. A new package is a new
  directory; no script edit.
- `--no-folding` in `.stowrc` links each file individually. It keeps `~/.config/zsh/` a real
  directory, so `~/.config/zsh/secrets` is not written into the working tree.
- `~/.config/nvim` stays a real directory — LazyVim writes lockfiles and caches there. A real
  `~/.zshrc` (the distro's or Oh-My-Zsh's) is moved to `~/.zshrc.pre-stow` once before stowing.
- After stowing, `stow.sh` removes symlinks that dangle into `stow/` and the directories that
  emptied. A stale link is otherwise still discovered — a deleted skill kept loading that way.
  `-n` reports instead.

**Secrets**

- `bw-restore.sh` and `bw-upload.zsh` are the only Bitwarden entry points.
- `bw-restore.sh` sets `NODE_TLS_REJECT_UNAUTHORIZED=0` around `bw` on purpose: the corporate CA
  that would validate the connection is itself in the vault and is installed only at the end of
  the restore. Writes run under `umask 077`; the vault cache is a mode-600 `mktemp` file removed
  by an `EXIT` trap.
- `BW_SESSION` is never written to disk. Persisting it put the unlock key in
  `~/.config/zsh/secrets`, which is uploaded back into the vault it unlocks.
- Infrastructure-identifying values live in `~/.config/zsh/secrets` as variables (`JIRA_*`,
  `NEXUS_SERVER_ID`, `WORK_K8S_*`, `WIN_USER`, the kubeconfig aliases), and in `~/.claude/local/`
  as markdown for skills and commands.

**tmux sessions**

- Every interactive shell outside tmux and SSH starts tmux. With `TMUX_MAIN=1` it runs `tm`,
  otherwise a plain new session. The flag is set in `~/.config/zsh/local.zsh`, an optional
  per-machine file that is never tracked or synced, so only machines that opt in (work) build
  `main`; `tm` still works by hand everywhere, and `prefix r` heals `main` only while it runs. There is no session restore, so a
  deformed `main` is healed on the next start. `tm` creates only the missing windows of `main`
  (existing ones and their panes are left alone), attaches, then kills every other session.
  `main` has windows 1 terminal, 2 nvim, 3 lf, 4 lazygit, 5 k9s (context from `$TMUX_K9S_CONTEXT`), 0 jirlab.
  `prefix r` reloads the config, heals `main` the same way (running apps survive), prunes the rest.
  `Alt-d` splits a pane and starts the window's app in the new one (a second lf, lazygit, nvim,
  k9s, jirlab); closing it closes the pane. `renumber-windows` is off so numbers stay fixed.
- While window 0's jirlab runs, `main`'s status bar is jirlab's header (logo, health pulse and system
  meters, four rows) on every window, with the session (red while the prefix is pending) and window list right of
  the top row, and window 0 shows jirlab
  without it. jirlab writes the rows to `$XDG_RUNTIME_DIR/jirlab-header` (`JIRLAB_HEADER_FILE`) and
  refreshes the status bar when they change. When it exits or the window has failed, `main` gets the
  normal one-line status back. Split jirlab panes and jirlab outside `main` keep their own header.
- No project is hard-wired. nvim reopens the last directory given to `v <dir>` (home before the
  first); a different directory restarts nvim clean (`:confirm qa`), the same one keeps its buffers;
  `v <file>` always runs in place; lazygit starts in home and `notARepository: skip` makes it open its most recent
  repository. Sending lazygit to the repository it already shows keeps it running; another repository relaunches it.
- Numpad `0`-`6` select windows 0-6, `7` / `9` move to the previous / next window and `8` to the next session (with no other session it opens one at the current dir, named after it): Windows Terminal types a digit for the numpad, so its `settings.json` (outside this repo) maps `numpad0`-`numpad9` to `\eOp`-`\eOy`, which tmux binds as `KP0`-`KP9`. Alt letters are avoided: LazyVim and others use them.
- Inside `main`, `v`/`vim`/`nvim` (no args), `lf`, `lg`, `k9s` and `jl` switch to windows 2, 3, 4, 5 and 0
  (at the current dir) instead of starting a second copy; anywhere else, or when `main` is not
  running, they run in place. Prefix with `h` (`h lf`, `h lg <dir>`, `h vfoo`) to run in place inside `main` too.
- Every `cd <dir>` alias (from `secrets` or `aliases.zsh`) gets `v<alias>` (nvim) and `g<alias>`
  (lazygit) twins, generated at shell start; in `main` they use the dedicated windows.
- Quitting nvim, lazygit, k9s or jirlab in `main` returns to the window that was active before it,
  however it was reached (numpad, `lg`, lf); the terminal window is only the fallback. Each app runs
  under a supervisor (`tmux-main.sh run`) that restarts it after a quit; three exits within 3 s in a
  row make it give up, leave the error on screen and become a plain shell (`@app failed`). `v`, `lg`,
  `k9s`, `jl` and lf then relaunch it, so a failed window is retried, never looped on or a dead end.
  Relaunch replaces only the supervised pane, never splits; `tm` creates missing windows but never
  restarts an existing one; concurrent starts are serialised by a lock.
- lf `e` / `q` jump to the nvim / terminal window at the current dir (`Q` quits lf). The terminal window's
  active pane at a shell prompt gets its input line cleared and `cd`; if it runs another app
  (e.g. `claude`), a new pane is split open at that dir instead. The `jirlab` function
  does the same with the nav file: a bare dir goes to the terminal window, `vim:<dir>`,
  `git:<dir>` to those windows, outside `main` it falls back to `cd`.

**Posting TLS**

- `stow/posting/.config/posting/config.yaml` sets `ssl.ca_bundle` to the system bundle. Posting's
  HTTP client is Python's, which ships its own certificate list and ignores the OS store, so
  internal hosts fail verification until the config says otherwise. It lives in the config, not
  in the shell, so every way of starting Posting (jirlab, a tmux window, a script) is covered.

**Posting focus**

- `stow/posting/.local/bin/posting-focus` wraps Posting instead of patching it: it runs Posting
  under the uv tool's own Python and replaces the collection tree's mount hook, so a uv upgrade
  never loses the change. With `JIRLAB_POSTING_FOCUS` set (jirlab sets it after an import) the
  tree collapses and opens only on that folder, with its login request (else the first) opened; unset, or on a name mismatch, Posting starts as
  usual. jirlab falls back to plain `posting` when the wrapper is missing.

**Runtime state**

- `~/.claude.json` (MCP servers) and `~/.claude/settings.json` (hooks) are written through CLIs,
  never stowed. `settings.json` holds machine-local work context and stays untracked.
- `~/.serena/serena_config.yml` carries absolute paths and a project list, so it is not stowed
  either. `install.sh` appends the two Java settings and leaves the upstream comments alone.
  Serena is Cursor-only (`--context ide`); Claude has its own `jdtls-lsp` plugin.

## AI assistant configuration

Skills and agents are authored once in `stow/claude/.claude/`; Cursor discovers them from
`~/.claude`. `stow/cursor/` holds only `rules/*.mdc`, `commands/*.md`, and `mcp.json`.
`check-ai-parity.sh`, run by `stow.sh`, fails on any `skills/` or `agents/` under it.
`~/.cursor/local` symlinks to `~/.claude/local`. The `ai-config` skill owns the rest.

## Bootstrap — `install.sh`

The order follows three constraints: TLS fails until the corporate CA is installed, WSL2 appends
the Windows `PATH` (a Windows `bw.exe` can shadow the Linux `bw`), and every step must be safe to
re-run on a half-bootstrapped machine.

| Step | Does |
|------|------|
| **1. APT** | `packages/apt.txt`, including `npm` — `bw` must exist before mise |
| **2. WSL PATH guard** | Non-System32 `/mnt/c/` on `PATH` → copies `host/wsl.conf` to `/etc/wsl.conf` and exits; run `wsl --shutdown`, then re-run |
| **3. BW CLI** | `@bitwarden/cli` and `tree-sitter-cli` via npm into `~/.npm-global` |
| **4. Secrets + certs** | Offers `bw-restore.sh`, which also installs the corporate CA; TLS validates normally from here |
| **5. Oh-My-Zsh** | OMZ, `zsh-autosuggestions`, `zsh-syntax-highlighting`, Powerlevel10k |
| **6. GitHub binaries** | `jirlab`, pinned to a commit and SHA256-verified; the PlantUML jar, pinned to 1.2026.6 (newer releases cannot render dividers inside groups as text) and SHA256-verified; `cursor-agent` from Cursor's installer (the npm package of that name is unrelated) |
| **7. Default shell** | `chsh` to zsh |
| **8. mise** | Runtimes and CLI tools from `.mise.toml` |
| **9. SDKMAN** | Upstream installer with `rcupdate=false` — `.zshrc` already sources it. Then the newest Temurin 21 (`JAVA_MAJOR`, resolved from the SDKMAN API, which lists only the latest patch per major) and Maven |
| **10. Stow** | `stow.sh` |
| **11. tmux TPM** | Clones TPM |
| **12. Git identity** | `~/.gitconfig_local` from `GIT_USER_NAME`/`GIT_USER_EMAIL`, or a prompt |
| **13. MCP servers** | `~/.claude/bin/install-mcp-servers.sh` registers into `~/.claude.json` |
| **14. uv tools** | `packages/uv-tools.txt` — including `serena-agent` (Cursor's code intelligence) and `posting` (HTTP TUI) |
| **15. Post-install** | `addcerts.sh` (Java truststore — SDKMAN JDK), `Lazy! sync`, Serena's Java settings (after Mason has jdtls), tmux plugins, `repos-restore.sh` |

Every step follows one pattern — a presence guard, `run` (or `curl_pipe` for upstream installers)
so `--dry-run` holds:

```bash
step "Step name"
if <already-done-guard>; then
  skip "reason"
else
  run <command>
  ok "success message"
fi
```

## Bitwarden secrets

Secure notes under the `dotfiles/` prefix:

| BW item | Destination |
|---|---|
| `dotfiles/zsh_secrets` | `~/.config/zsh/secrets` |
| `dotfiles/git-credentials` | `~/.config/git/credentials` |
| `dotfiles/kube/config-<short>.yaml` | `~/.kube/config-<short>.yaml`; `kube-merge.sh` then builds `~/.kube/config` from them, one context per file named `<short>` (never uploaded) |
| `dotfiles/certs/<filename>` | `~/certs/<filename>` |
| `dotfiles/repos` | `$DOTFILES/repos.txt` |
| `dotfiles/ai/<filename>` | `~/.claude/local/<filename>` |

## Usage

```bash
git clone https://github.com/balazsando/dotfiles ~/dotfiles && cd ~/dotfiles
bash install.sh && exec zsh                         # new machine

bash stow.sh                                        # re-stow; -n for a dry run
mise run sync                                       # git pull --ff-only + re-stow
mise run update-tools                               # upgrade mise and uv tools
sindex                                              # index this repo into Serena's symbol cache
relocate ~/.config/somefile --package zsh           # move a $HOME file into a package
bash sync.sh                                        # before migrating: wsl.conf, repos, BW upload
bash ~/.local/share/dotfiles/scripts/bw-restore.sh  # restore secrets
zsh ~/.local/share/dotfiles/scripts/bw-upload.zsh   # upload secrets
```

Git identity lives in `~/.gitconfig_local`, untracked and included by `.gitconfig`:

```bash
git config --file ~/.gitconfig_local user.name  "Your Name"
git config --file ~/.gitconfig_local user.email "you@example.com"
```

New package: create `stow/<package>/` mirroring the path from `$HOME`, add the files, run
`bash stow.sh`.

## Known limitations

- `wsl.conf` changes need a full WSL restart; `install.sh` cannot continue past it.
- Bitwarden sessions expire; a bootstrap resumed after a long pause needs `bw unlock` again.
- `repos-restore.sh` skips repos it cannot clone (VPN-gated) — check its warnings.

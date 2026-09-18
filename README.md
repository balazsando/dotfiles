# dotfiles

Personal dotfiles for Debian/Ubuntu/WSL2, managed with
[GNU Stow](https://www.gnu.org/software/stow/) and [mise](https://mise.jdx.dev/).

[![Version](https://img.shields.io/badge/version-1.6.0-blue)](CHANGELOG.md)

The repository is public. What may enter a tracked file is ruled by `CLAUDE.md`, mirrored for
Cursor in `.cursor/rules/no-leaks.mdc`.

## Layout

```
dotfiles/
├── stow/                   # GNU Stow packages — each maps to $HOME
│   ├── bat/                # bat config + themes
│   ├── bin/                # Standalone binaries (win32yank.exe for the WSL clipboard)
│   ├── claude/             # Claude Code: CLAUDE.md, commands, skills, MCP
│   ├── cursor/             # Cursor: rules, commands, MCP (skills/agents shared from claude/)
│   ├── git/                # .gitconfig, .githooks, .config/git/ignore
│   ├── java/               # Maven settings, Eclipse formatter
│   ├── lf/                 # lf file manager
│   ├── mise/               # .mise.toml — runtimes, CLI tools, tasks
│   ├── nvim/               # LazyVim
│   ├── posting/            # Posting HTTP client
│   ├── scripts/            # Operational scripts → ~/.local/share/dotfiles/scripts/
│   ├── tmux/               # tmux
│   └── zsh/                # .zshrc, .p10k.zsh, ~/.config/zsh/ fragments
├── host/                   # Machine-specific config — copied, never symlinked
│   ├── wsl.conf            # → /etc/wsl.conf on WSL2
│   └── work-wsl/           # Work-machine WSL overrides
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

**Runtime state**

- `~/.claude.json` (MCP servers) and `~/.claude/settings.json` (hooks) are written through CLIs,
  never stowed. `settings.json` holds machine-local work context and stays untracked.
- [rtk](https://github.com/rtk-ai/rtk) is a `PreToolUse` hook that rewrites the agent's Bash calls
  (`git status` → `rtk git status`); `Read`/`Grep`/`Glob` bypass it. The `claude` and `ai` shell
  functions register it on launch when missing, so it self-heals after a `settings.json` reset.
  `rtk init --hook-only` writes nothing tracked. `rtk gain` shows the savings.
- codebase-memory-mcp comes from its upstream installer, not mise. The installer is pinned to a
  release commit and SHA256-verified, like `jirlab`, and `CBM_DOWNLOAD_URL` points it at the same
  release, whose `checksums.txt` it checks the binary against; bump `CBM_TAG`, `CBM_COMMIT` and
  `CBM_SHA256` together. It copies the binary to `~/.local/bin` and points its hooks at that
  path. `--clients=claude` also writes its three `codebase-memory*` agents, its skill, and its
  hooks into `~/.claude` — untracked, and the only agents on the machine. Cursor is left out because the installer would write an absolute path
  into the stowed `mcp.json`; it finds the agents and skill in `~/.claude`. `SHELL=/bin/sh`
  sends the installer's PATH line to `~/.profile` instead of the stowed `.zshrc`. Step 13
  registers the servers afterwards, replacing the absolute path it writes to `~/.claude.json`.

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
| **6. GitHub binaries** | `jirlab`, pinned to a commit and SHA256-verified; `cursor-agent` from Cursor's installer (the npm package of that name is unrelated) |
| **7. Default shell** | `chsh` to zsh |
| **8. mise** | Runtimes and CLI tools from `.mise.toml` |
| **9. SDKMAN** | Upstream installer with `rcupdate=false` — `.zshrc` already sources it. Then the newest Temurin 21 (`JAVA_MAJOR`, resolved from the SDKMAN API, which lists only the latest patch per major) and Maven |
| **10. Stow** | `stow.sh` |
| **11. tmux TPM** | Clones TPM |
| **12. Git identity** | `~/.gitconfig_local` from `GIT_USER_NAME`/`GIT_USER_EMAIL`, or a prompt |
| **13. MCP servers** | codebase-memory-mcp from its pinned, verified installer, then `~/.claude/bin/install-mcp-servers.sh` registers into `~/.claude.json` |
| **14. uv tools** | `packages/uv-tools.txt` |
| **15. Post-install** | `addcerts.sh` (Java truststore — SDKMAN JDK), `Lazy! sync`, tmux plugins, `repos-restore.sh` |

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
| `dotfiles/kube/<filename>` | `~/.kube/<filename>` |
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

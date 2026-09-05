# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and [mise](https://mise.jdx.dev/).  
Targeting **Debian/Ubuntu/WSL2**.

[![Version](https://img.shields.io/badge/version-1.0.1-blue)](CHANGELOG.md)

---

## Repository layout

```
dotfiles/
├── stow/                   # GNU Stow packages (each maps to $HOME)
│   ├── bat/                # bat syntax-highlighter config + themes
│   ├── bin/                # Standalone binaries
│   ├── claude/             # Claude Code: CLAUDE.md, agents, commands, skills, MCP
│   ├── cursor/             # Cursor: rules, agents, commands, skills, MCP
│   ├── git/                # .gitconfig + .config/git/{ignore,credentials}
│   ├── java/               # Maven settings, Eclipse formatter
│   ├── lf/                 # lf file manager config
│   ├── mise/               # .mise.toml — all runtimes and CLI tools
│   ├── nvim/               # LazyVim / Neovim config
│   ├── posting/            # Posting HTTP client config
│   ├── scripts/            # Operational scripts → ~/.local/share/dotfiles/scripts/
│   ├── tmux/               # tmux config
│   └── zsh/                # .zshrc, .p10k.zsh, ~/.config/zsh/ fragments
├── host/                   # Machine-specific config (copied, never symlinked)
│   └── wsl.conf            # Applied to /etc/wsl.conf on WSL2 machines
├── packages/
│   └── apt.txt             # System-level APT packages
├── docs/
│   └── ARCHITECTURE.md     # Design decisions and rationale
├── install.sh              # Bootstrap entry point — run once on a new machine
├── stow.sh                 # Idempotent re-stow — safe to run at any time
└── sync.sh                 # Pre-migration export (wsl.conf, repos, BW secrets)
```

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
| `dotfiles/ai/<filename>` | `~/.claude/local/` and `~/.cursor/local/` |

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


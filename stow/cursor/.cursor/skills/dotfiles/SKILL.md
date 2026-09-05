---
name: dotfiles
description: "Dotfiles management skill. Use when managing dotfiles with symlinks, bare git, Stow, chezmoi, yadm, or dotbot; setting up a new machine; writing idempotent bootstrap/install scripts; handling secrets (~/.zsh_secrets pattern); organizing configs for Zsh/Oh-My-Zsh/Powerlevel10k, Neovim/LazyVim, tmux/TPM, lf, fzf; migrating or syncing dotfiles across machines; using XDG base dirs; or structuring a dotfiles repo for any shell framework."
argument-hint: "Describe the task (e.g., 'add my nvim config', 'bootstrap new machine', 'keep secrets out of git', 'write an idempotent install.sh', 'compare stow vs chezmoi', 'migrate from bare git to stow')"
---

# Dotfiles Skill

## What are Dotfiles?

Configuration files (traditionally prefixed with `.`) that personalise your shell, editor, terminal, and tools. A dotfiles repository tracks these files under version control so they are reproducible, portable, and shared across machines.

Reference: https://dotfiles.github.io/

---

## Management Strategies

| Approach | Best for | Notes |
|---|---|---|
| **Symlink farm (manual)** | Small setups | `ln -sf ~/dotfiles/.zshrc ~/.zshrc`; fragile at scale |
| **GNU Stow** | Modular packages, pure symlinks | Groups files into "packages"; installs via symlink farm |
| **chezmoi** | Multi-machine, templating, secrets | Go binary; explicit state management; encrypts secrets |
| **yadm** | git-centric, minimal extra tooling | Wraps git; branches per machine; no symlinks |
| **dotbot** | Python, declarative YAML config | install block config; runs on `./install` |
| **Bare git repo** | Zero dependencies | `git --git-dir=$HOME/.dotfiles --work-tree=$HOME` |
| **rcm** | `thoughtbot`-style; per-hostname overrides | `rcup`, `mkrc`, `lsrc` |

---

## This Repo Layout

```
~/dotfiles/
├── stow/
│   ├── claude/.claude/        # Claude Code config
│   │   ├── CLAUDE.md          # Global instructions
│   │   ├── mcp-servers.json   # MCP source of truth (applied via bin/install-mcp-servers.sh)
│   │   ├── agents/            # Subagent definitions
│   │   ├── commands/          # Slash commands
│   │   └── skills/            # Skill reference documents
│   ├── cursor/.cursor/        # Cursor agents, rules, skills, MCP
│   │   ├── mcp.json           # Global Cursor MCP config
│   │   ├── rules/             # Global .mdc rules (alwaysApply)
│   │   ├── agents/            # Custom Cursor agents
│   │   ├── commands/          # Cursor slash commands
│   │   └── skills/            # Skill reference documents
│   ├── zsh/.config/zsh/       # Zsh config, aliases, functions
│   ├── nvim/.config/nvim/     # Neovim / LazyVim config
│   ├── tmux/.config/tmux/     # tmux config
│   └── ...
├── install.sh                 # Idempotent bootstrap script
├── stow.sh                    # Auto-discover + restow all packages
└── .stowrc                    # Global stow flags (--no-folding)
```

Both `.claude/` (Claude Code) and `.cursor/` (Cursor IDE) coexist.
Stow the cursor package with: `cd ~/dotfiles && stow cursor`

Secrets that should never be committed live in `~/.config/zsh/secrets` (sourced by `.zshrc`, excluded from git).

---

## Idempotent Install Script Pattern

A good `install.sh` is **safe to run multiple times** — it creates only what's missing.

```bash
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
LOG_PREFIX="[dotfiles]"

# ── Helpers ───────────────────────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

log_step() { echo "${LOG_PREFIX} $*"; }

link() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    log_step "Backing up existing $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  if [ ! -L "$dst" ]; then
    log_step "Linking $dst"
    ln -sf "$src" "$dst"
  fi
}

install_if_missing() {
  local pkg="$1"
  if ! has "$pkg"; then
    log_step "Installing $pkg"
    sudo apt-get install -y "$pkg"
  else
    log_step "$pkg already installed — skipping"
  fi
}

# ── Symlinks ──────────────────────────────────────────────────────────────────
link "$DOTFILES/.zshrc"      "$HOME/.zshrc"
link "$DOTFILES/.p10k.zsh"   "$HOME/.p10k.zsh"
link "$DOTFILES/.zsh_aliases" "$HOME/.zsh_aliases"

# ── Tools ─────────────────────────────────────────────────────────────────────
install_if_missing zsh
install_if_missing tmux
install_if_missing fzf

# ── Oh-My-Zsh ─────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log_step "Installing Oh-My-Zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ── TPM (tmux plugin manager) ─────────────────────────────────────────────────
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  log_step "Installing TPM"
  git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

log_step "Done."
```

### Key patterns

| Pattern | Why |
|---|---|
| `has()` guard | Skip if binary already on PATH |
| `log_step()` | Visible progress without noise |
| Backup before link | Preserve pre-existing user files |
| `--unattended` flags | Non-interactive installs in CI / fresh machines |
| `set -euo pipefail` | Fail fast on any error, unbound var, or pipeline failure |

---

## Sync Script Pattern (`sync.sh`)

Used before migrating to a new tool or before a major restructure — exports current live state back into the dotfiles repo.

```bash
#!/usr/bin/env bash
# sync.sh — copy live configs into the dotfiles repo
set -euo pipefail

DOTFILES="$HOME/dotfiles"

sync_file() {
  local src="$1" dst="$2"
  if [ -f "$src" ]; then
    echo "Syncing $src → $dst"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
}

sync_file "$HOME/.zshrc"          "$DOTFILES/.zshrc"
sync_file "$HOME/.p10k.zsh"       "$DOTFILES/.p10k.zsh"
sync_file "$HOME/.tmux.conf"      "$DOTFILES/.tmux.conf"
sync_file "$HOME/.gitconfig"      "$DOTFILES/.gitconfig"
sync_file "$HOME/.config/lf/lfrc" "$DOTFILES/.config/lf/lfrc"

echo "Done. Review changes with: git -C $DOTFILES diff"
```

---

## Secrets Management

**Never commit secrets to git.**

### Pattern: `~/.zsh_secrets`

```zsh
# ~/.zshrc — source secrets if file exists
[ -f "$HOME/.zsh_secrets" ] && source "$HOME/.zsh_secrets"
```

```zsh
# ~/.zsh_secrets (NEVER commit this file)
export GITHUB_TOKEN="ghp_..."
export ANTHROPIC_API_KEY="sk-ant-..."
export JIRA_API_TOKEN="..."
export AWS_ACCESS_KEY_ID="..."
```

```bash
# .gitignore (in dotfiles repo root)
.zsh_secrets
*.secret
*.token
.env
.env.*
```

### Secrets via chezmoi + age encryption

```bash
chezmoi add --encrypt ~/.zsh_secrets
# stores as: ~/.local/share/chezmoi/encrypted_dot_zsh_secrets.age
```

### Secrets via keyring / password manager

```zsh
# Fetch at shell startup (once per session)
export GITHUB_TOKEN=$(secret-tool lookup service github user bando 2>/dev/null || echo "")
```

---

## Shell Frameworks

### Oh-My-Zsh

```zsh
# ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git z fzf docker kubectl)
source "$ZSH/oh-my-zsh.sh"
```

```bash
# Install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Update
omz update

# Custom plugin dir
~/.oh-my-zsh/custom/plugins/
```

### Powerlevel10k (p10k)

```zsh
# Install (manual / oh-my-zsh plugin)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Configure (interactive wizard)
p10k configure

# Config lives in: ~/.p10k.zsh  ← commit this!
```

### antidote (fast Zsh plugin manager)

```zsh
# ~/.zsh_plugins.txt
ohmyzsh/ohmyzsh path:lib/git.zsh
romkatv/powerlevel10k
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
Aloxaf/fzf-tab
```

```zsh
# ~/.zshrc
source "$HOME/.antidote/antidote.zsh"
antidote load
```

---

## Tool Configs in This Repo

### Neovim / LazyVim

```
dotfiles/.config/nvim/
├── init.lua
├── lua/
│   ├── config/
│   │   ├── autocmds.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   └── options.lua
│   └── plugins/
│       └── *.lua          # custom plugin specs
```

```bash
# Bootstrap LazyVim
git clone https://github.com/LazyVim/starter ~/.config/nvim
```

### tmux + TPM

```bash
# ~/.tmux.conf
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install plugins (inside tmux)
# prefix + I
```

### lf (terminal file manager)

```
dotfiles/.config/lf/
├── lfrc          # main config
└── icons         # icon definitions
```

### fzf

```zsh
# ~/.zshrc
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
```

---

## Adding a New Config File

```bash
# 1. Identify the live config path
echo "~/.config/alacritty/alacritty.toml"

# 2. Create the matching path in dotfiles
mkdir -p ~/dotfiles/.config/alacritty

# 3. Move and symlink (or let Stow do it)
mv ~/.config/alacritty/alacritty.toml ~/dotfiles/.config/alacritty/
ln -sf ~/dotfiles/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml

# ── OR with Stow ──────────────────────────────────────────────────────────────
mkdir -p ~/dotfiles/alacritty/.config/alacritty
mv ~/.config/alacritty/alacritty.toml ~/dotfiles/alacritty/.config/alacritty/
cd ~/dotfiles && stow alacritty

# ── OR with chezmoi ───────────────────────────────────────────────────────────
chezmoi add ~/.config/alacritty/alacritty.toml

# 4. Commit
git -C ~/dotfiles add -A
git -C ~/dotfiles commit -m "chore: add alacritty config"
```

---

## Multi-Machine Strategies

### Branches per machine

```bash
# main branch — shared base
git checkout -b work        # work-specific overrides
git checkout -b home        # home machine config
git merge main              # pull in base changes
```

### chezmoi templates

```
{{ if eq .chezmoi.hostname "work-laptop" }}
export HTTPS_PROXY="http://proxy.corp:8080"
{{ end }}
```

### yadm alternates

```bash
# File named: .gitconfig##hostname.work-laptop
# yadm auto-selects based on hostname / OS / user
```

### `~/.zsh_local` pattern (sourced last)

```zsh
# ~/.zshrc (committed)
[ -f "$HOME/.zsh_local" ] && source "$HOME/.zsh_local"
```

```zsh
# ~/.zsh_local (NOT committed — machine-specific)
export WORK_PROXY="http://proxy.corp:8080"
alias vpn="openconnect vpn.corp.com"
```

---

## XDG Base Directory Support

```zsh
# ~/.zshrc or ~/.zprofile
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
```

Move configs to XDG paths when apps support it:

```zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"            # ~/.config/zsh/.zshrc
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export VIMINIT="set nocp | source $XDG_CONFIG_HOME/vim/vimrc"
```

---

## New Machine Bootstrap Checklist

```bash
# 1. Install git (usually present)
sudo apt-get update && sudo apt-get install -y git curl

# 2. Clone dotfiles
git clone https://github.com/yourname/dotfiles ~/dotfiles

# 3. Run install script
cd ~/dotfiles && bash install.sh

# 4. Install Zsh and switch shell
sudo apt-get install -y zsh
chsh -s "$(which zsh)"

# 5. Install Neovim (AppImage or package)
sudo apt-get install -y neovim   # or use AppImage

# 6. Start Neovim (LazyVim auto-installs plugins on first run)
nvim

# 7. Start tmux + install TPM plugins
tmux new -s main
# prefix + I  (install plugins)

# 8. Set up secrets file
touch ~/.zsh_secrets && chmod 600 ~/.zsh_secrets
echo "export GITHUB_TOKEN=..." >> ~/.zsh_secrets
```

---

## Git Submodules for Plugins

```bash
# Add oh-my-zsh as submodule (alternative to script install)
git submodule add https://github.com/ohmyzsh/ohmyzsh .oh-my-zsh

# Clone with submodules on new machine
git clone --recurse-submodules https://github.com/yourname/dotfiles ~/dotfiles

# Update all submodules
git submodule update --remote --merge
```

---

## Common Gotchas

| Problem | Fix |
|---|---|
| Symlink points to wrong relative path | Use absolute paths in `ln -sf` |
| install.sh runs but changes don't load | `source ~/.zshrc` or open new terminal |
| Oh-My-Zsh overwrites `.zshrc` on install | Run install with `--keep-zshrc` flag |
| p10k wizard resets on new machine | Commit `.p10k.zsh`; wizard only runs if file missing |
| Secrets appear in `git diff` | Verify `.gitignore` is committed; check `git status` |
| Tool not found after install | Check PATH; may need new shell session |
| TPM plugins not loading | Run `prefix + I` inside tmux; check `~/.tmux/plugins/` |
| LazyVim not finding plugins | Ensure `~/.config/nvim` is symlinked or on correct path |
| WSL2 path issues | Avoid `/mnt/c/` paths in configs; keep everything in `~` |
| `ln -sf` fails with "too many levels of symbolic links" | Destination already is a symlink to the same target; skip |

---

## Quick Reference Card

```bash
# Link a file manually
ln -sf ~/dotfiles/.zshrc ~/.zshrc

# Stow a package
cd ~/dotfiles && stow zsh

# chezmoi add / apply
chezmoi add ~/.zshrc
chezmoi apply

# Run install script (idempotent)
bash ~/dotfiles/install.sh

# Sync live configs back to repo
bash ~/dotfiles/sync.sh

# New machine full bootstrap
git clone https://github.com/yourname/dotfiles ~/dotfiles && bash ~/dotfiles/install.sh

# Check for dangling symlinks
find ~ -maxdepth 3 -type l ! -exec test -e {} \; -print 2>/dev/null

# See what chezmoi would change
chezmoi diff

# See what stow would do (dry run)
cd ~/dotfiles && stow -nv zsh

# Update oh-my-zsh
omz update

# Update tmux plugins (inside tmux)
# prefix + U
```

---

## Quality Checklist

- [ ] `install.sh` is idempotent — safe to run on a fresh machine and on an existing one
- [ ] `~/.zsh_secrets` (or equivalent) is in `.gitignore`
- [ ] `set -euo pipefail` at the top of every shell script
- [ ] Symlinks use absolute source paths (`~/dotfiles/...` not relative)
- [ ] `.p10k.zsh`, `.zsh_aliases`, and `.zsh_functions` are all committed
- [ ] Tool install guards use `has()` / `command -v` before running installs
- [ ] Backups created before overwriting pre-existing user files
- [ ] New machine checklist tested on a clean VM or WSL2 instance
- [ ] Secrets verified absent with `git log -p | grep -i token` / `git secret scan`

---

## Key References

- Dotfiles community: https://dotfiles.github.io/
- Tutorial list: https://dotfiles.github.io/tutorials/
- Utility index: https://dotfiles.github.io/utilities/
- Shell framework comparison: https://dotfiles.github.io/frameworks/
- GitHub topic: https://github.com/topics/dotfiles
- Awesome dotfiles: https://github.com/webpro/awesome-dotfiles
- Oh-My-Zsh: https://ohmyz.sh/
- Powerlevel10k: https://github.com/romkatv/powerlevel10k
- GNU Stow manual: https://www.gnu.org/software/stow/manual/stow.html
- chezmoi docs: https://www.chezmoi.io/

# Dotfiles — general patterns

Background and tooling this repo does not itself use (chezmoi, yadm, dotbot, bare git,
antidote), plus the reusable install-script, shell-framework, multi-machine, XDG, and
submodule patterns. Read when the task goes beyond this repo's own Stow setup.

---

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


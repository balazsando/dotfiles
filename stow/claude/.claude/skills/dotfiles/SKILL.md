---
name: dotfiles
description: "Dotfiles repositories: symlinks, bare git, Stow, chezmoi, yadm, dotbot; new-machine setup; idempotent bootstrap and install scripts; keeping secrets out of git; XDG base dirs; organising Zsh, Neovim/LazyVim, tmux, lf and fzf configs; migrating or syncing across machines."
argument-hint: "Describe the task (e.g., 'add my nvim config', 'bootstrap new machine', 'keep secrets out of git', 'write an idempotent install.sh', 'compare stow vs chezmoi', 'migrate from bare git to stow')"
---

# Dotfiles Skill

This repo is **Stow-based** (`stow/` packages, `.stowrc`, `stow.sh`, `install.sh`, `sync.sh`); the
sections below describe it. General background — the strategy comparison (chezmoi, yadm, dotbot,
bare git), the reusable idempotent install-script template, shell frameworks (Oh-My-Zsh, p10k,
antidote), multi-machine strategies, XDG base dirs, and plugin submodules — lives in
`references/patterns.md`. Read that when the task goes beyond this repo's own setup.

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
│   ├── cursor/.cursor/        # Cursor rules, commands, MCP
│   │   ├── mcp.json           # Global Cursor MCP config
│   │   ├── rules/             # Global .mdc rules (alwaysApply)
│   │   └── commands/          # Cursor slash commands
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

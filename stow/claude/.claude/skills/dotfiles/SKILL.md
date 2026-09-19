---
name: dotfiles
description: "Dotfiles repositories: symlinks, bare git, Stow, chezmoi, yadm, dotbot; new-machine setup; idempotent bootstrap and install scripts; keeping secrets out of git; XDG base dirs; organising Zsh, Neovim/LazyVim, tmux, lf and fzf configs; migrating or syncing across machines."
argument-hint: "Describe the task (e.g., 'add my nvim config', 'bootstrap new machine', 'keep secrets out of git', 'write an idempotent install.sh', 'compare stow vs chezmoi', 'migrate from bare git to stow')"
---

# Dotfiles

## This repository

Stow-based. `README.md` is authoritative for the layout, the load-bearing decisions, the bootstrap
steps, and where secrets live — read it before a structural change; never restate it here.

- A package is `stow/<name>/` mirroring the path from `$HOME`. Apply with `bash stow.sh`, never a
  bare `stow`: it runs the parity guard, removes known conflicts, and prunes dangling links.
- `bash stow.sh -n` before and after a structural change; check the symlinks resolve.
- Move a live file in with `relocate <path> --package <pkg>`.
- Secrets live in `~/.config/zsh/secrets` and `~/.claude/local/`, moved only by `bw-restore.sh`
  and `bw-upload.zsh`. Never a tracked file.
- Every `install.sh` step is guarded and re-runnable, and honours `--dry-run` through `run`.
- `~/.claude.json` is written by `~/.claude/bin/install-mcp-servers.sh`; never hand-edit it.
- Structure, bootstrap flow, or package list changed → update `README.md` in the same change.
- Unclear target platform, two packages that could own one file, or a move that could clobber
  unversioned local changes → ask.

General background — strategy comparison (chezmoi, yadm,
dotbot, bare git), an idempotent install template, shell frameworks, multi-machine setups, XDG
base dirs — is `references/patterns.md`.

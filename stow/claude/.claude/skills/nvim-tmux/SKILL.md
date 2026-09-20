---
name: nvim-tmux
description: "tmux in this setup, and Neovim running inside it: .tmux.conf bindings, prefix, pane navigation, plugins, terminal colours."
argument-hint: "the tmux or Neovim-in-tmux change"
---

# tmux

Config is `~/.config/tmux/tmux.conf` (stowed from `stow/tmux/`), not `~/.tmux.conf`. Prefix is
`C-a`; `prefix r` reloads. Root-table bindings: `M-arrow` switches panes, `M-d` splits along the
longer side, `M-w` kills the pane. `default-terminal` is `screen-256color` with RGB via
`terminal-overrides` — keep Neovim's `termguicolors` consistent with it. Plugins through TPM,
including `tmux-resurrect`, `tmux-continuum` and `tmux-sessionx` (`prefix s`).

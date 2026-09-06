---
name: nvim-tmux
description: "Neovim and tmux together: keybindings, splits, pane navigation, scripting sessions, sending commands between panes, and .tmux.conf / Neovim Lua integration."
argument-hint: "Describe the tmux/Neovim setup task (e.g., 'configure pane navigation', 'set up session layout', 'integrate clipboard')"
---

# Neovim + tmux Skill

## Core Concepts

### tmux Hierarchy
```
Server → Sessions ($id) → Windows (@id) → Panes (%id)
```
- **Session**: persistent group of windows; survives disconnects
- **Window**: full-screen tab; split into panes
- **Pane**: individual pseudo-terminal

### Default Prefix
`C-b` — all key bindings follow the prefix unless bound with `-n` (root table)

---

## Essential tmux Commands Cheatsheet

| Goal | Command / Key |
|---|---|
| New session | `tmux new -s name` |
| Attach session | `tmux attach -t name` |
| Detach | `C-b d` |
| List sessions | `tmux ls` |
| New window | `C-b c` |
| Split horizontal | `C-b "` |
| Split vertical | `C-b %` |
| Navigate panes | `C-b` + arrow key |
| Zoom pane | `C-b z` |
| Kill pane | `C-b x` |
| Rename window | `C-b ,` |
| Move to window N | `C-b N` |
| Copy mode | `C-b [` |
| Paste buffer | `C-b ]` |
| Reload config | `tmux source ~/.tmux.conf` |

### Target Syntax
```
session:window.pane   # e.g. mysession:1.%2
$1:@2.%3              # by ID
:                     # current session
```

---

## Common .tmux.conf Patterns

```sh
# Change prefix to C-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse
set -g mouse on

# Use vi keys in copy mode
set -g mode-keys vi

# Start windows/panes at 1
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on

# Faster escape (important for Neovim!)
set -sg escape-time 10

# True color support
set -g default-terminal "tmux-256color"
set -sa terminal-features ",xterm-256color:RGB"

# Reload config binding
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# Intuitive splits
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Status bar
set -g status-left "[#S] "
set -g status-right "#(date '+%H:%M') "
set -g status-style "bg=colour235,fg=colour250"
```

---

## Neovim + tmux Integration Patterns

### 1. Seamless Pane/Window Navigation (vim-tmux-navigator style)
Install `christoomey/vim-tmux-navigator` or replicate manually:

```lua
-- In Neovim: navigate to tmux panes when at window edge
local function navigate(dir)
  local win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. dir)
  if vim.api.nvim_get_current_win() == win then
    -- Didn't move — at edge, send to tmux
    local tmux_dir = ({ h = "L", j = "D", k = "U", l = "R" })[dir]
    vim.fn.system("tmux select-pane -" .. tmux_dir)
  end
end

vim.keymap.set("n", "<C-h>", function() navigate("h") end, { desc = "Navigate left" })
vim.keymap.set("n", "<C-j>", function() navigate("j") end, { desc = "Navigate down" })
vim.keymap.set("n", "<C-k>", function() navigate("k") end, { desc = "Navigate up" })
vim.keymap.set("n", "<C-l>", function() navigate("l") end, { desc = "Navigate right" })
```

Corresponding `.tmux.conf` bindings:
```sh
bind -n C-h run "(tmux display-message -p '#{pane_current_command}' | grep -iq nvim && tmux send-keys C-h) || tmux select-pane -L"
bind -n C-j run "(tmux display-message -p '#{pane_current_command}' | grep -iq nvim && tmux send-keys C-j) || tmux select-pane -D"
bind -n C-k run "(tmux display-message -p '#{pane_current_command}' | grep -iq nvim && tmux send-keys C-k) || tmux select-pane -U"
bind -n C-l run "(tmux display-message -p '#{pane_current_command}' | grep -iq nvim && tmux send-keys C-l) || tmux select-pane -R"
```

### 2. Send Commands from Neovim to a tmux Pane
```lua
-- Send current line or selection to adjacent tmux pane
local function send_to_tmux(text)
  -- Escape single quotes
  text = text:gsub("'", "'\\''")
  vim.fn.system(string.format("tmux send-keys -t '{right-of}' '%s' Enter", text))
end

vim.keymap.set("n", "<leader>ts", function()
  send_to_tmux(vim.api.nvim_get_current_line())
end, { desc = "Send line to tmux" })
```

### 3. Run Current File in tmux Split
```lua
vim.keymap.set("n", "<leader>rf", function()
  local file = vim.fn.expand("%:p")
  local ft = vim.bo.filetype
  local cmd = ({
    python = "python3 " .. file,
    lua = "lua " .. file,
    sh = "bash " .. file,
  })[ft] or file
  vim.fn.system(string.format("tmux split-window -h '%s'", cmd))
end, { desc = "Run file in tmux split" })
```

### 4. Open Neovim Terminal vs tmux Pane Decision
- Prefer **Neovim's built-in terminal** (`:term`) for short-lived commands tied to the editor
- Prefer **tmux panes** for persistent processes (servers, watchers, REPLs)

```lua
-- Quick terminal toggle (Neovim built-in)
vim.keymap.set("n", "<leader>tt", function()
  vim.cmd("botright 15split | terminal")
end, { desc = "Open terminal split" })
```

---

## tmux Scripting: Session Layouts

### Shell Script to Bootstrap a Dev Session
```sh
#!/bin/sh
SESSION="dev"
tmux has-session -t "$SESSION" 2>/dev/null && tmux attach -t "$SESSION" && exit

tmux new-session -d -s "$SESSION" -n "editor" -c "$HOME/projects/myapp"
tmux send-keys -t "$SESSION:editor" "nvim ." Enter

tmux new-window -t "$SESSION" -n "server" -c "$HOME/projects/myapp"
tmux send-keys -t "$SESSION:server" "npm run dev" Enter

tmux new-window -t "$SESSION" -n "shell" -c "$HOME/projects/myapp"

tmux select-window -t "$SESSION:editor"
tmux attach -t "$SESSION"
```

### Lua Helper to Start tmux Sessions from Neovim
```lua
local function tmux_session(name, cmds)
  if vim.fn.system("tmux has-session -t " .. name .. " 2>/dev/null; echo $?"):match("^0") then
    return  -- already exists
  end
  vim.fn.system("tmux new-session -d -s " .. name)
  for _, cmd in ipairs(cmds) do
    vim.fn.system(string.format("tmux send-keys -t %s '%s' Enter", name, cmd))
  end
end
```

---

## tmux Formats & Status Line

Format variables use `#{variable}`:
```sh
# Useful variables
#{session_name}   #{window_name}   #{pane_title}
#{pane_current_path}  #{pane_current_command}
#{window_index}   #{window_flags}   #{host}

# Conditional: #{?condition,true,false}
set -g status-right "#{?client_prefix,#[fg=red]PREFIX ,}#H %H:%M"

# Run shell command in status
set -g status-right "#(uptime | awk -F'[a-z]:' '{print $2}') %H:%M"
```

---

## Neovim Inside tmux: Key Settings

These Neovim options matter specifically in tmux:

```lua
-- True color (must match tmux config)
vim.opt.termguicolors = true

-- Faster escape from insert mode
vim.opt.ttimeoutlen = 0

-- Clipboard integration via tmux or xclip
vim.opt.clipboard = "unnamedplus"

-- Report terminal title to tmux
vim.opt.title = true
vim.opt.titlestring = "%t — nvim"

-- Avoid background color erase issues
-- (handled by: set -g default-terminal "tmux-256color" in tmux)
```

---

## Workflow: Step-by-Step

1. **Bootstrap**: Start tmux session with named windows per concern (editor, server, shell)
2. **Enter Neovim**: Open in the `editor` window with `nvim .`
3. **Navigate**: Use `C-h/j/k/l` to move seamlessly between nvim splits and tmux panes
4. **Send code**: Use `<leader>ts` to REPL-drive code from the buffer
5. **Copy text**: Enter copy mode with `C-b [`, use vi keys (`v`, `y`), paste with `C-b ]`
6. **Zoom when focused**: `C-b z` to temporarily maximize a pane
7. **Persist work**: Detach (`C-b d`) — session survives; reattach later with `tmux attach -t dev`

---

## Common Gotchas

| Problem | Fix |
|---|---|
| Colors wrong in nvim inside tmux | Set `default-terminal "tmux-256color"` and `terminal-features ",*:RGB"` |
| Escape delay in nvim | `set -sg escape-time 10` in tmux |
| `$TERM` wrong inside tmux | Always `tmux-256color` or `screen-256color`; never `xterm-256color` directly |
| Clipboard not working | Install `xclip`/`wl-copy`; set `set-clipboard on` in tmux; use `unnamedplus` in nvim |
| Neovim not detecting tmux | `$TMUX` env var must be set; check with `:echo $TMUX` |
| Nested tmux prefix collision | Use `C-b C-b` to send prefix to inner tmux, or remap outer prefix |

---

## Quality Checklist

- [ ] `escape-time` ≤ 10ms in tmux (Neovim mode-switch lag fix)
- [ ] `termguicolors = true` in Neovim + matching `terminal-features` in tmux
- [ ] Pane navigation uses consistent keys in both tmux and Neovim
- [ ] Session scripts are idempotent (`has-session` check before creating)
- [ ] `send-keys` calls escape shell-special characters
- [ ] Clipboard works end-to-end (tmux buffer ↔ system clipboard ↔ Neovim)
- [ ] `TERM` is set to `tmux-256color` inside tmux sessions

---

## References

- `man tmux` — full reference
- `:help terminal` — Neovim built-in terminal
- `:help 'clipboard'` — Neovim clipboard config
- https://neovim.io/doc/user/lua/ — Neovim Lua stdlib
- https://github.com/christoomey/vim-tmux-navigator — seamless navigation plugin

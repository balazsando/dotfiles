# tmux configuration — `.tmux.conf` patterns, formats, status line

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

# tmux scripting — session layouts from shell and Lua

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

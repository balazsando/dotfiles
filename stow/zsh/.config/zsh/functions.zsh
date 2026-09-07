#!/usr/bin/env zsh

# addcerts — sourced for interactive use; actual logic lives in addcerts.sh
addcerts() { bash "${DOTFILES:-$HOME/dotfiles}/stow/scripts/.local/share/dotfiles/scripts/addcerts.sh" "$@"; }

# claude / ai — register the rtk hook for the agent if missing, then launch it
_rtk_hooked() {
  command -v rtk >/dev/null || return 0
  rtk init --show 2>/dev/null | grep -q "^\[ok\] $2" ||
    rtk init -g --agent "$1" --hook-only --auto-patch >/dev/null
}
claude() { _rtk_hooked claude 'settings.json'; command claude "$@"; }
ai()     { _rtk_hooked cursor 'Cursor hook';   command cursor-agent "$@"; }

# lfcd — lf file manager with cd-on-quit
lfcd() {
  local tmp dir
  tmp="$(mktemp)"
  command lf -last-dir-path="$tmp" "$@"
  [[ -f "$tmp" ]] || return
  dir="$(cat "$tmp")"
  rm -f "$tmp"
  [[ -d "$dir" ]] && cd "$dir"
}
alias lf='lfcd'

# idea — open IntelliJ for the nearest Maven project root
idea() {
  local idea_sh dir
  idea_sh=$(find ~/.cache/JetBrains/RemoteDev/dist -name idea.sh 2>/dev/null | head -n 1)
  dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/pom.xml" ]] && break
    dir=$(dirname "$dir")
  done
  "$idea_sh" "$dir" >/dev/null 2>&1 &
}

# ver — print (and clipboard-copy) the Maven revision from .mvn/maven.config
ver() {
  local file=".mvn/maven.config"
  [[ -f "$file" ]] || return 0
  local line ver
  line=$(grep '^-Drevision=' "$file") || return 0
  ver="${line#-Drevision=}"
  ver="${ver// /}"
  if command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$ver" | clip.exe
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$ver" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$ver" | xclip -selection clipboard
  fi
  printf '\033[0;36m%s\033[0m\n' "$ver"
}

# jirlab — TUI wrapper that handles post-exit directory navigation
jirlab() {
  # Path is hardcoded in the jirlab binary, so it cannot move. Validate before
  # trusting it — /tmp is world-writable and this is used as a cd target.
  local nav_file="/tmp/jirlab_nav" dir
  rm -f "$nav_file"
  command jirlab "$@"
  [[ -f "$nav_file" && ! -L "$nav_file" && -O "$nav_file" ]] || { rm -f "$nav_file"; return; }
  dir="$(<"$nav_file")"
  rm -f "$nav_file"
  [[ -n "$dir" && -d "$dir" ]] && cd "$dir"
}

# jwtdecode — decode and pretty-print a JWT payload
jwtdecode() {
  local payload="${1#*.}"
  payload="${payload%%.*}"
  local rem=$(( ${#payload} % 4 ))
  (( rem == 2 )) && payload+="=="
  (( rem == 3 )) && payload+="="
  payload="${payload//-/+}"
  payload="${payload//_//}"
  printf '%s' "$payload" | base64 -d | jq .
}

# fv — fuzzy file finder → open in nvim
fv() {
  local file
  file=$(command fd -H -t f . | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:70%)
  [[ -n "$file" ]] && nvim "$file"
}

# fcd — fuzzy directory navigation
fcd() {
  local dir
  dir=$(command fd -H -t d . | fzf \
    --preview 'eza --tree --level=3 --color=always {} | head -300' \
    --preview-window=right:60% \
    --header='ENTER cd | CTRL-O open nvim')
  [[ -n "$dir" ]] && cd "$dir"
}

# fgb — fuzzy git branch checkout
fgb() {
  local branch
  branch=$(git branch --all | sed 's/^..//' | sed 's#remotes/origin/##' | sort -u | \
    fzf --preview 'git log --oneline --graph --decorate --color=always -20 {}' --preview-window=right:70%)
  [[ -n "$branch" ]] && git checkout "$branch"
}

# fgr — fuzzy ripgrep → open match in nvim
fgr() {
  local result
  result=$(rg --line-number --no-heading . | fzf --delimiter ':' \
    --preview 'bat --style=numbers --color=always {1} --highlight-line {2}')
  [[ -n "$result" ]] && nvim "$(echo "$result" | cut -d: -f1)" +"$(echo "$result" | cut -d: -f2)"
}

# fk — fuzzy process killer
fk() {
  local pids
  pids=$(ps -ef | sed 1d | fzf -m \
    --header='TAB multi-select | ENTER kill TERM | CTRL-K force kill' \
    --preview 'echo {}' \
    --bind 'ctrl-k:execute-silent(echo {} | awk "{print \$2}" | xargs -r kill -9)+abort')
  [[ -n "$pids" ]] && echo "$pids" | awk '{print $2}' | xargs -r kill
}

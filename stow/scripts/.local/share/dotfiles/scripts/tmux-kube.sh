#!/usr/bin/env bash
# Usage: tmux-kube.sh [-n] up <kd|km>

set -euo pipefail

DRY=0
[[ ${1:-} == -n ]] && { DRY=1; shift; }

die() { echo "tmux-kube.sh: $*" >&2; exit 1; }
t() { if ((DRY)); then echo "tmux $*"; else tmux "$@"; fi; }

[[ ${1:-} == up && ${2:-} =~ ^(kd|km)$ ]] || die "usage: tmux-kube.sh [-n] up <kd|km>"
SESSION=$2
command -v tmux >/dev/null || die "tmux is not installed"
command -v zsh >/dev/null || die "zsh is not installed"
[[ -f $HOME/.config/zsh/secrets ]] || die "$HOME/.config/zsh/secrets is missing (run bw-restore.sh)"

PREFIX=d
[[ $SESSION == km ]] && PREFIX=m

envs=$(zsh -fc '
  source "$HOME/.config/zsh/secrets" 2>/dev/null
  for n v in ${(kv)aliases}; do
    [[ $n == ${1}* && $v == "cd "* ]] || continue
    e=${n#$1}
    k=${aliases[k${e}m]:-${aliases[k$e]:-}}
    [[ $1 == m && -n $k ]] || k=${aliases[k$e]:-}
    [[ $k =~ "KUBECONFIG=\"([^\"]+)\"" ]] || continue
    kc=${match[1]//\$HOME/$HOME}
    print -r -- "$e|$kc|${${v#cd }/#\~/$HOME}"
  done | sort' _ "$PREFIX")
[[ -n $envs ]] || die "no $SESSION environments found in ~/.config/zsh/secrets"

alive() { tmux has-session -t "$SESSION" 2>/dev/null; }
has_window() { tmux list-windows -t "$SESSION" -F '#I' 2>/dev/null | grep -qx "$1"; }

i=0
while IFS='|' read -r env kc dir; do
  i=$((i + 1))
  name=$env
  [[ $SESSION == km ]] && name+=m
  [[ -d $dir ]] || { echo "tmux-kube.sh: skipping $env, $dir is missing" >&2; i=$((i - 1)); continue; }
  k9s="while :; do KUBECONFIG=$(printf %q "$kc") k9s; done"
  vim="while :; do f=\$(find $(printf %q "$dir") -maxdepth 2 -name 'values*.y*ml' 2>/dev/null | sort | head -n1); command nvim \"\${f:-.}\"; done"
  if alive; then
    if has_window "$i"; then
      t kill-pane -a -t "$SESSION:$i"
      t respawn-window -k -c "$dir" -t "$SESSION:$i" "$k9s"
    else
      t new-window -d -c "$dir" -t "$SESSION:$i" "$k9s"
    fi
  else
    t new-session -d -s "$SESSION" -n "$name" -c "$dir" "$k9s"
  fi
  t rename-window -t "$SESSION:$i" "$name"
  t set-option -w -t "$SESSION:$i" automatic-rename off
  t split-window -h -c "$dir" -t "$SESSION:$i" "$vim"
  t select-pane -t "$SESSION:$i.1"
done <<<"$envs"
((i)) || die "no usable $SESSION environment (every repository path is missing)"
t select-window -t "$SESSION:1"

#!/usr/bin/env bash
# Usage: tmux-main.sh [-n] up | attach | reload | prune | back <n> | vim-dir | go <term|vim|lf|git|k9s|jira> [dir|context]

set -euo pipefail

SESSION=main
KEEP="main kd km"
KUBE="$HOME/.local/share/dotfiles/scripts/tmux-kube.sh"
SOCK="${XDG_RUNTIME_DIR:-/tmp}/nvim-$SESSION.sock"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-main-vim-dir"
DRY=0
[[ ${1:-} == -n ]] && { DRY=1; shift; }

die() { echo "tmux-main.sh: $*" >&2; exit 1; }
t() { if ((DRY)); then echo "tmux $*"; else tmux "$@"; fi; }

command -v tmux >/dev/null || die "tmux is not installed"

keep() { echo "while :; do $2; $HOME/.local/share/dotfiles/scripts/tmux-main.sh back $1; done"; }

declare -A NAME=([1]=terminal [2]=vim [3]=lf [4]=lazygit [5]=k9s [0]=jirlab)
declare -A DIR=([1]="$HOME" [2]="$HOME" [3]="$HOME" [4]="$HOME" [5]="$HOME" [0]="$HOME")
declare -A RUN=(
  [1]=""
  [2]="$(keep 2 "cd \"\$($HOME/.local/share/dotfiles/scripts/tmux-main.sh vim-dir)\"; rm -f $SOCK; command nvim --listen $SOCK .")"
  [3]="command lf"
  [4]="$(keep 4 lazygit)"
  [5]="$(keep 5 "env -u KUBECONFIG k9s --context ${TMUX_K9S_CONTEXT:-}")"
  [0]="$(keep 0 "jirlab board")"
)

alive() { tmux has-session -t "$SESSION" 2>/dev/null; }
has_window() { tmux list-windows -t "$SESSION" -F '#I' 2>/dev/null | grep -qx "$1"; }
fg_of() { tmux display-message -p -t "$SESSION:$1" '#{pane_current_command}'; }
is_shell() { [[ $1 == zsh || $1 == bash || $1 == sh ]]; }

type_line() {
  t send-keys -t "$SESSION:$1" -l "$2"
  t send-keys -t "$SESSION:$1" Enter
}

spawn() {
  local w=$1 dir=$2 run=$3
  if has_window "$w"; then
    t kill-pane -a -t "$SESSION:$w"
    t respawn-window -k -c "$dir" -t "$SESSION:$w"
  else
    t new-window -d -c "$dir" -t "$SESSION:$w"
  fi
  t rename-window -t "$SESSION:$w" "${NAME[$w]}"
  t set-option -w -t "$SESSION:$w" automatic-rename off
  if [[ -n $run ]]; then type_line "$w" "$run"; fi
}

up() {
  local w
  [[ -n ${TMUX_K9S_CONTEXT:-} ]] || die "TMUX_K9S_CONTEXT is not set (add it to ~/.config/zsh/secrets)"
  alive || t new-session -d -s "$SESSION" -n "${NAME[1]}" -c "${DIR[1]}"
  for w in 1 2 3 4 5 0; do spawn "$w" "${DIR[$w]}" "${RUN[$w]}"; done
  if alive; then
    for w in $(tmux list-windows -t "$SESSION" -F '#I'); do
      [[ -n ${NAME[$w]:-} ]] || t kill-window -t "$SESSION:$w"
    done
  fi
  t set-option -w -t "$SESSION:5" @ctx "$TMUX_K9S_CONTEXT"
  t select-window -t "$SESSION:0"
}

kube_up() {
  local s
  for s in kd km; do
    tmux has-session -t "$s" 2>/dev/null && continue
    if ((DRY)); then "$KUBE" -n up "$s" || true; else "$KUBE" up "$s" || echo "tmux-main.sh: session $s not built" >&2; fi
  done
}

prune() {
  local s cur=
  alive || return 0
  [[ -z ${TMUX:-} ]] || cur=$(tmux display-message -p '#S')
  if [[ -n $cur && " $KEEP " != *" $cur "* ]]; then t switch-client -t "$SESSION"; fi
  while read -r s; do
    [[ " $KEEP " == *" $s "* ]] || t kill-session -t "$s"
  done < <(tmux list-sessions -F '#S')
}

reload() {
  local cur=
  [[ -z ${TMUX:-} ]] || cur=$(tmux display-message -p '#S')
  case $cur in
    kd | km) "$KUBE" up "$cur" || true; alive || up ;;
    *) up ;;
  esac
  kube_up
  prune
}

attach() {
  alive || up
  kube_up
  prune
  if [[ -n ${TMUX:-} ]]; then t switch-client -t "$SESSION"; else exec tmux attach -t "$SESSION"; fi
}

go() {
  alive || die "session '$SESSION' is not running (run: tmux-main.sh attach)"
  local what=${1:?usage: tmux-main.sh go <term|vim|lf|git|k9s|jira> [dir|context]} arg=${2:-} w fg
  case $what in
    term)
      w=1
      if [[ -n $arg ]]; then
        fg=$(fg_of "$w")
        if is_shell "$fg"; then type_line "$w" "cd $(printf %q "$arg")"; else t split-window -c "$arg" -t "$SESSION:$w"; fi
      fi
      ;;
    vim)
      w=2
      if [[ -n $arg ]]; then
        ((DRY)) || { mkdir -p "${STATE%/*}"; printf %s "$arg" >"$STATE"; }
        fg=$(fg_of "$w")
        if [[ $fg == nvim ]]; then
          if ((DRY)); then echo "nvim --server $SOCK --remote-send :cd $arg"; else
            nvim --server "$SOCK" --remote-send "<C-\\><C-n>:cd ${arg// /\\ }<CR>"
          fi
        elif is_shell "$fg"; then
          type_line "$w" "cd $(printf %q "$arg") && ${RUN[2]}"
        fi
      fi
      ;;
    lf)
      w=3
      [[ -z $arg ]] || spawn "$w" "$arg" "${RUN[3]}"
      ;;
    git)
      w=4
      spawn "$w" "${arg:-${DIR[4]}}" "${RUN[4]}"
      ;;
    k9s)
      w=5
      if [[ -n $arg ]]; then
        if [[ $(fg_of "$w") == k9s ]]; then
          if [[ $(tmux show-option -wqv -t "$SESSION:$w" @ctx) != "$arg" ]]; then
            t send-keys -t "$SESSION:$w" Escape
            ((DRY)) || sleep 0.3
            t send-keys -t "$SESSION:$w" -l ":ctx $arg"
            t send-keys -t "$SESSION:$w" Enter
          fi
        else
          spawn "$w" "${DIR[5]}" "$(keep 5 "env -u KUBECONFIG k9s --context $arg")"
        fi
        t set-option -w -t "$SESSION:$w" @ctx "$arg"
      fi
      ;;
    jira) w=0 ;;
    *) die "unknown window '$what'" ;;
  esac
  if [[ -n ${TMUX:-} ]] && ((! DRY)); then
    src=$(tmux display-message -p '#S:#I')
    [[ $src == "$SESSION:$w" ]] || tmux set-option -w -t "$SESSION:$w" @ret "$src"
  fi
  t switch-client -t "$SESSION:$w"
}

back() {
  local r
  r=$(tmux show-option -wqv -t "$SESSION:${1:?window}" @ret 2>/dev/null || true)
  tmux switch-client -t "${r:-$SESSION:1}" 2>/dev/null || tmux switch-client -t "$SESSION:1"
}

case "${1:-attach}" in
  up) up ;;
  attach) attach ;;
  vim-dir) d=$(cat "$STATE" 2>/dev/null || true); [[ -d $d ]] && echo "$d" || echo "$HOME" ;;
  reload) reload ;;
  back) back "${2:-}" ;;
  prune) prune ;;
  go) shift; go "$@" ;;
  *) die "usage: tmux-main.sh [-n] up | attach | reload | prune | go <term|vim|lf|git|k9s|jira> [dir|context]" ;;
esac

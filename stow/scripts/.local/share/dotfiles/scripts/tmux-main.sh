#!/usr/bin/env bash
# Usage: tmux-main.sh [-n] up | attach | reload | prune | split [-h|-v] | back <n> | vim-dir | go [-d] <term|vim|lf|git|k9s|jira> [dir|context]

set -uo pipefail

SELF="$HOME/.local/share/dotfiles/scripts/tmux-main.sh"
SESSION=main
KEEP="main"
RT="${XDG_RUNTIME_DIR:-/tmp}"
SOCK="$RT/nvim-$SESSION.sock"
LOCK="$RT/tmux-$SESSION.lock"
HDR="$RT/jirlab-header"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-main-vim-dir"
FAST=3
MAXFAST=3
DRY=0
[[ ${1:-} == -n ]] && { DRY=1; shift; }

die() { echo "tmux-main.sh: $*" >&2; exit 1; }
tmux() { command tmux "$@" 9>&-; }
t() { if ((DRY)); then echo "tmux $*" >&2; else tmux "$@"; fi; }

command -v tmux >/dev/null || die "tmux is not installed"

declare -A NAME=([1]=terminal [2]=vim [3]=lf [4]=lazygit [5]=k9s [0]=jirlab)

alive() { tmux has-session -t "$SESSION" 2>/dev/null; }
has_window() { tmux list-windows -t "$SESSION" -F '#I' 2>/dev/null | grep -qx "$1"; }
opt() { tmux show-option -wqv -t "$SESSION:$1" "$2" 2>/dev/null; }
pane_of() {
  local p
  p=$(opt "$1" @pane)
  if [[ -n $p ]] && tmux display-message -p -t "$p" '#{pane_id}' >/dev/null 2>&1; then echo "$p"; else echo "$SESSION:$1"; fi
}
fg_of() { tmux display-message -p -t "$(pane_of "$1")" '#{pane_current_command}'; }
is_shell() { [[ ${1#-} == zsh || ${1#-} == bash || ${1#-} == sh ]]; }
healthy() { has_window "$1" && [[ $(opt "$1" @app) == running ]]; }
ctx_of() { local c; c=$(opt 5 @ctx); echo "${c:-${TMUX_K9S_CONTEXT:-}}"; }
known_ctx() {
  command -v kubectl >/dev/null || return 0
  env -u KUBECONFIG kubectl config get-contexts -o name 2>/dev/null | grep -qxF -- "$1"
}
startable() {
  [[ $1 != 5 || -n $(ctx_of) ]] && return 0
  echo "tmux-main.sh: TMUX_K9S_CONTEXT is not set (add it to ~/.config/zsh/secrets); skipping k9s" >&2
  return 1
}

vim_dir() {
  local d
  d=$(cat "$STATE" 2>/dev/null || true)
  [[ -f $d ]] && d=$(dirname "$d")
  [[ -d $d ]] && echo "$d" || echo "$HOME"
}
vim_open() { local d; d=$(cat "$STATE" 2>/dev/null || true); [[ -f $d ]] && echo "$d" || echo .; }
nvr() { timeout --foreground 3 nvim --server "$SOCK" --remote-send "$1" </dev/null >/dev/null 2>&1; }
nvim_up() { timeout --foreground 2 nvim --server "$SOCK" --remote-expr 1 </dev/null >/dev/null 2>&1; }
repo_of() { git -C "$1" rev-parse --show-toplevel 2>/dev/null || echo "$1"; }

# While window 0's jirlab runs, the status bar of main is its header (4 rows read from $HDR), with the
# session and window list right of the top row; otherwise main gets the global status line back.
header() {
  local i f
  if [[ $1 == off ]]; then
    rm -f "$HDR"
    t set-option -u -t "$SESSION" status
    t set-option -u -t "$SESSION" status-format
    return 0
  fi
  f=$(printf %q "$HDR")
  for i in 1 2 3; do t set-option -t "$SESSION" "status-format[$i]" "#(sed -n $((i + 1))p $f 2>/dev/null)"; done
  t set-option -t "$SESSION" 'status-format[0]' "#(sed -n 1p $f 2>/dev/null)#[align=right]#[push-default]#{T:status-left}#[pop-default]#[default]#{W:#[range=window|#{window_index}]#{T:window-status-format}#[norange default],#[range=window|#{window_index}]#{T:window-status-current-format}#[norange default]}"
  t set-option -t "$SESSION" status 4
}

# One instance of window $1's app, in the foreground.
app() {
  local c
  case $1 in
    2)
      if [[ ${2:-} == split ]]; then command nvim
      else cd "$(vim_dir)" && rm -f "$SOCK" && command nvim --listen "$SOCK" "$(vim_open)"; fi ;;
    3) command lf ;;
    4) command lazygit ;;
    5)
      c=$(ctx_of)
      [[ -n $c ]] || { echo "TMUX_K9S_CONTEXT is not set (add it to ~/.config/zsh/secrets)" >&2; return 2; }
      env -u KUBECONFIG k9s --context "$c" ;;
    0)
      [[ ${2:-} == split ]] && { jirlab board; return; }
      header on
      JIRLAB_HEADER_FILE=$HDR jirlab board || c=$?
      header off
      return "${c:-0}" ;;
  esac
}

# After a normal quit: go back, but only if this window is the one being looked at.
after_exit() {
  local w=$1 ts act
  if [[ $w == 2 ]]; then
    ts=$(opt 2 @restart)
    if [[ -n $ts ]]; then
      tmux set-option -wu -t "$SESSION:2" @restart
      (( $(date +%s) - ts < 30 )) && return 0
    fi
  fi
  act=$(tmux display-message -p -t "$SESSION:$w" '#{window_active}' 2>/dev/null)
  [[ $act == 1 ]] || return 0
  if [[ $w == 0 ]]; then tmux select-window -t "$SESSION:1"
  else tmux select-window -l -t "$SESSION" 2>/dev/null || tmux select-window -t "$SESSION:1"; fi
}

# Window supervisor: restarts the app after a normal quit; after $MAXFAST quick exits in a row
# it gives up, leaves the error on screen and becomes a plain shell. It never loops.
run() {
  local w=$1 start rc fast=0
  set -m
  trap : INT
  while :; do
    start=$SECONDS; rc=0
    app "$w" || rc=$?
    if (( SECONDS - start < FAST )); then
      (( ++fast >= MAXFAST )) && break
      (( rc == 0 )) && after_exit "$w"
    else
      fast=0
      after_exit "$w"
    fi
  done
  tmux set-option -w -t "$SESSION:$w" @app failed
  echo "tmux-main.sh: ${NAME[$w]} keeps exiting (last status $rc). This shell stays; the next 'go' retries it." >&2
  exec "${SHELL:-bash}" -i
}

# Split pane: one run of the app, held open on failure so the error can be read.
once() {
  local rc=0
  app "$1" split || rc=$?
  (( rc == 0 )) && return 0
  echo "tmux-main.sh: ${NAME[$1]} exited ($rc)" >&2
  read -rsn1 -p "press a key"
}

# (Re)start window $1 under its supervisor. Only the supervised pane is touched, never user splits.
launch() {
  local w=$1 dir=${2:-$HOME} cmd p
  [[ -d $dir ]] || dir=$HOME
  cmd="$(printf %q "$SELF") run $w"
  if has_window "$w"; then
    p=$(pane_of "$w")
    t respawn-pane -k -c "$dir" -t "$p" "$cmd"
  else
    p=$(t new-window -d -P -F '#{pane_id}' -c "$dir" -t "$SESSION:$w" -n "${NAME[$w]}" "$cmd")
  fi
  t set-option -w -t "$SESSION:$w" automatic-rename off
  t set-option -w -t "$SESSION:$w" @app running
  t set-option -wu -t "$SESSION:$w" @restart
  [[ -z $p ]] || t set-option -w -t "$SESSION:$w" @pane "$p"
}

want() { healthy "$1" || { startable "$1" && launch "$1" "${2:-}"; }; }

up() {
  local w fresh=0
  alive || { fresh=1; t new-session -d -s "$SESSION" -n "${NAME[1]}" -c "$HOME" || die "cannot create session '$SESSION'"; }
  has_window 1 || t new-window -d -c "$HOME" -t "$SESSION:1" -n "${NAME[1]}"
  t set-option -w -t "$SESSION:1" automatic-rename off
  for w in 2 3 4 5 0; do
    has_window "$w" || { startable "$w" && launch "$w"; }
  done
  if ((fresh)); then t select-window -t "$SESSION:0"; fi
  return 0
}

split() {
  local flag=${1:--h} sess w
  sess=$(tmux display-message -p '#S')
  w=$(tmux display-message -p '#I')
  if [[ $sess == "$SESSION" && $w != 1 && -n ${NAME[$w]:-} ]]; then
    t split-window "$flag" -c '#{pane_current_path}' "$(printf %q "$SELF") once $w"
  else
    t split-window "$flag" -c '#{pane_current_path}'
  fi
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

reload() { alive || return 0; up; prune; }

attach() {
  up
  prune
  if [[ -n ${TMUX:-} ]]; then t switch-client -t "$SESSION"
  elif ((DRY)); then echo "tmux attach -t $SESSION" >&2
  else exec tmux attach -t "$SESSION" 9>&-; fi
}

go() {
  alive || die "session '$SESSION' is not running (run: tmux-main.sh attach)"
  local stay=0
  [[ ${1:-} == -d ]] && { stay=1; shift; }
  local what=${1:?usage: tmux-main.sh go [-d] <term|vim|lf|git|k9s|jira> [dir|context]} arg=${2:-} w
  case $what in
    term)
      w=1
      if [[ -n $arg ]]; then
        if is_shell "$(fg_of "$w")"; then
          t send-keys -t "$SESSION:$w" C-u
          t send-keys -t "$SESSION:$w" -l "cd $(printf %q "$arg")"
          t send-keys -t "$SESSION:$w" Enter
        else
          t split-window -h -c "$arg" -t "$SESSION:$w"
        fi
      fi
      ;;
    vim)
      w=2
      if [[ -z $arg ]]; then want 2
      else
        local prev dir=$arg
        [[ -d $arg ]] || dir=$(dirname "$arg")
        prev=$(vim_dir)
        ((DRY)) || { mkdir -p "${STATE%/*}"; printf %s "$arg" >"$STATE"; }
        if ! healthy 2; then launch 2
        elif ((DRY)) || nvim_up; then
          if [[ $prev != "$dir" ]]; then
            t set-option -w -t "$SESSION:2" @restart "$(date +%s)"
            ((DRY)) || nvr "<C-\\><C-n>:confirm qa<CR>" || launch 2
          elif [[ -f $arg ]]; then
            ((DRY)) || nvr "<C-\\><C-n>:edit ${arg// /\\ }<CR>" || true
          fi
        fi
      fi
      ;;
    lf) if [[ -n $arg ]]; then launch 3 "$arg"; else want 3; fi ;;
    git)
      local repo
      repo=$(repo_of "${arg:-$HOME}")
      if ! healthy 4 || [[ $(opt 4 @gitdir) != "$repo" ]]; then
        launch 4 "${arg:-$HOME}"
        t set-option -w -t "$SESSION:4" @gitdir "$repo"
      fi
      ;;
    k9s)
      w=5
      if [[ -n $arg ]]; then
        known_ctx "$arg" || die "context '$arg' is not in ~/.kube/config (run kube-merge.sh)"
        if ! healthy 5 || [[ $(opt 5 @ctx) != "$arg" ]]; then
          t set-option -w -t "$SESSION:5" @ctx "$arg"
          launch 5
        fi
      else
        want 5
      fi
      ;;
    jira) want 0 ;;
    *) die "unknown window '$what'" ;;
  esac
  case $what in term) w=1 ;; vim) w=2 ;; lf) w=3 ;; git) w=4 ;; k9s) w=5 ;; jira) w=0 ;; esac
  ((stay)) || t switch-client -t "$SESSION:$w"
}

cmd=${1:-attach}
case $cmd in
  up|attach|reload|go)
    exec 9>"$LOCK" || die "cannot open lock $LOCK"
    flock -w 15 9 || die "another tmux-main.sh holds $LOCK" ;;
esac

case $cmd in
  up) up ;;
  attach) attach ;;
  vim-dir) vim_dir ;;
  vim-open) vim_open ;;
  reload) reload ;;
  split) shift; split "$@" ;;
  back) after_exit "${2:-}" ;;
  run) run "${2:?window}" ;;
  once) once "${2:?window}" ;;
  prune) prune ;;
  go) shift; go "$@" ;;
  *) die "usage: tmux-main.sh [-n] up | attach | reload | prune | split [-h|-v] | go [-d] <term|vim|lf|git|k9s|jira> [dir|context]" ;;
esac

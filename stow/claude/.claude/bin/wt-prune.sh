#!/usr/bin/env bash
# Removes orphaned delivery worktrees (change-delivery §3): idle for WT_PRUNE_HOURS (default 12),
# clean, and no process inside. A dirty orphan is kept and reported. The branch stays, unless its
# tip is already in the base (nothing to review). Branches are never pushed or rewritten.
#   wt-prune.sh [-n|--dry-run] [--hook]    --hook: quiet unless something happened
set -uo pipefail

root="${XDG_STATE_HOME:-$HOME/.local/state}/worktrees"
hours="${WT_PRUNE_HOURS:-12}"
dry=0 hook=0
for a in "$@"; do
  case $a in
    -n | --dry-run) dry=1 ;;
    --hook) hook=1 ;;
    *) echo "usage: wt-prune.sh [-n|--dry-run] [--hook]" >&2; exit 1 ;;
  esac
done
[[ -d $root ]] || exit 0
command -v git >/dev/null || { echo "wt-prune: git not found" >&2; exit 1; }

say() { echo "wt-prune: $*" >&2; }
busy() {
  local p d
  for p in /proc/[0-9]*/cwd; do d=$(readlink "$p" 2>/dev/null) && [[ $d == "$1" || $d == "$1/"* ]] && return 0; done
  return 1
}

prune() {
  local wt=$1 main branch
  main=$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
    say "kept $wt — its repository is gone; remove it by hand"; return; }
  main=${main%/.git}
  [[ -n $(find "$wt" -path "$wt/.git" -prune -o -newermt "$hours hours ago" -print -quit 2>/dev/null) ]] && return
  busy "$wt" && return
  if [[ -n $(git -C "$wt" status --porcelain 2>/dev/null) ]]; then
    say "kept $wt — uncommitted changes, idle > ${hours}h"; return
  fi
  branch=$(git -C "$wt" symbolic-ref --short -q HEAD)
  ((dry)) && { say "would remove $wt${branch:+ (branch $branch)}"; return; }
  git -C "$main" worktree remove --force "$wt" && say "removed $wt"
  if [[ -n $branch ]] && git -C "$main" merge-base --is-ancestor "$branch" refs/remotes/origin/HEAD 2>/dev/null; then
    git -C "$main" branch -D "$branch" >/dev/null && say "deleted $branch — nothing beyond the base"
  fi
  git -C "$main" worktree prune
}

walk() {
  local d
  for d in "$1"/*/; do
    d=${d%/}
    [[ -d $d ]] || continue
    if [[ -f $d/.git ]]; then prune "$d"; else walk "$d"; fi
  done
}

walk "$root"
((dry)) || find "$root" -mindepth 1 -type d -empty -delete 2>/dev/null
((hook)) || say "done ($root, idle > ${hours}h)"
exit 0

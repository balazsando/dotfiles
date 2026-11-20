#!/usr/bin/env bash
# Self-check for the AI hooks in stow/claude/.claude/bin: git-guard.sh and wt-prune.sh.
set -uo pipefail

bin="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stow/claude/.claude/bin"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export XDG_STATE_HOME="$tmp/state"
W="$XDG_STATE_HOME/worktrees" fail=0

guard() {
  local want=$1 cmd=$2 cwd=${3:-/repos/x} got
  jq -cn --arg c "$cmd" --arg d "$cwd" '{tool_input: {command: $c}, cwd: $d}' | bash "$bin/git-guard.sh" >/dev/null 2>&1
  [[ $? == 2 ]] && got=block || got=allow
  [[ $got == "$want" ]] || { echo "✗ git-guard: want $want, got $got: $cmd"; fail=1; }
}
guard allow "git status && git diff"
guard allow "git fetch --prune origin"
guard allow "git branch --show-current"
guard allow "git switch release"
guard allow "git worktree add --no-track -b f/x $W/r/f/x origin/release"
guard block "git commit -m x"
guard block "git add README.md"
guard block "git -C /repos/r push origin f/x"
guard block "git reset --hard HEAD~1"
guard block "git branch f/y"
guard block "git checkout -b f/z"
guard allow "git -C $W/r/f/x commit -m x"
guard allow "git commit -m x" "$W/r/f/x"
guard block "git -C $W/r/f/x commit --no-verify -m x"
guard block "git -C $W/r/f/x push --force origin f/x"
guard allow "git -C $W/r/f/x push --force-with-lease origin f/x"

g() { git -c user.name=t -c user.email=t@example.invalid "$@"; }
g init -q --bare "$tmp/origin.git"
g clone -q "$tmp/origin.git" "$tmp/main" 2>/dev/null
g -C "$tmp/main" checkout -q -b trunk
g -C "$tmp/main" commit -q --allow-empty -m init
g -C "$tmp/main" push -q origin HEAD:main
g -C "$tmp/main" remote set-head origin main >/dev/null
for b in idle-empty idle-dirty idle-commit fresh; do
  g -C "$tmp/main" worktree add -q --no-track -b "$b" "$W/main/$b" origin/main
done
g -C "$W/main/idle-commit" commit -q --allow-empty -m work
echo x >"$W/main/idle-dirty/new.txt"
for b in idle-empty idle-dirty idle-commit; do find "$W/main/$b" -exec touch -h -d '2 days ago' {} +; done
bash "$bin/wt-prune.sh" --hook 2>/dev/null

wts=$(g -C "$tmp/main" worktree list --porcelain | grep -c '^worktree ')
branches=$(g -C "$tmp/main" branch --format='%(refname:short)' | sort | tr '\n' ' ')
[[ $wts == 3 ]] || { echo "✗ wt-prune: want main + idle-dirty + fresh, got $wts worktrees"; fail=1; }
[[ $branches == "fresh idle-commit idle-dirty trunk " ]] || { echo "✗ wt-prune: branches left: $branches"; fail=1; }

((fail)) && exit 1
echo "✔ AI hooks: git-guard and wt-prune behave"

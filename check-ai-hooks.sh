#!/usr/bin/env bash
# Self-check for the AI hooks: git-guard, leak-guard, and wt-prune in stow/claude/.claude/bin, and
# the commit-msg git hook. dotfiles-check runs this file, so it is not tested here.
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
guard allow "git -C $W/r/f/x add README.md src/a.java"
guard block "git -C $W/r/f/x add -A"
guard block "git -C $W/r/f/x add -- ."
guard block "git -C $W/r/f/x add -A && git -C $W/r/f/x commit -m x"
guard allow "git -C $W/r/f/x add pom.xml app/pom.xml && git -C $W/r/f/x commit -m 'fix-x. -A'"
guard allow "git -C $W/r/f/x add README.md docs; ls -A ."
guard block "glab mr create --description 'x

Generated with [Claude Code](https://claude.com/claude-code)'"

# expect <hook> <want> <name> [args] — stdin is the hook input.
expect() {
  local got; bash "$bin/$1" "${@:4}" >/dev/null 2>&1
  [[ $? == 2 ]] && got=block || got=allow
  [[ $got == "$2" ]] || { echo "✗ $1: want $2, got $got: $3"; fail=1; }
}
foot='Fixes it.\n\nGenerated with [Claude Code](https://claude.com/claude-code)'
jq -cn --arg d "$foot" '{tool_name: "mcp__gitlab__create_merge_request", tool_input: {description: $d}}' |
  expect git-guard.sh block "Claude MCP merge request with attribution"
jq -cn --arg d "$foot" '{tool_name: "create_merge_request", tool_input: ({description: $d} | tojson)}' |
  expect git-guard.sh block "Cursor MCP merge request with attribution"
jq -cn '{tool_name: "mcp__gitlab__create_merge_request", tool_input: {description: "Fixes it."}}' |
  expect git-guard.sh allow "merge request without attribution"

export DOTFILES_DIR="$tmp/dot" LEAK_TERMS="$tmp/terms.md"
printf '# terms\n\nsecret-host\n' >"$LEAK_TERMS"
mkdir -p "$DOTFILES_DIR" && ln -s "$DOTFILES_DIR" "$tmp/link"
leak() { jq -cn --arg p "$2" --arg c "$3" --arg o "${4:-}" '{tool_input: {file_path: $p, new_string: $c, old_string: $o}}' | expect leak-guard.sh "$1" "$2 ← $3"; }
leak block "$DOTFILES_DIR/a.md" "url https://SECRET-HOST/x"
leak block "$tmp/link/a.md" "secret-host via a stowed symlink"
leak allow "$DOTFILES_DIR/a.md" "url \$HOST" "secret-host"
leak allow "$DOTFILES_DIR/a.md" "" "host: secret-host"
leak allow "$tmp/elsewhere/a.md" "secret-host outside the repo"
git init -q "$DOTFILES_DIR" && echo "secret-host" >"$DOTFILES_DIR/b.md" && git -C "$DOTFILES_DIR" add b.md
(cd "$DOTFILES_DIR" && expect leak-guard.sh block "staged term" --staged </dev/null)
unset DOTFILES_DIR LEAK_TERMS

hooks="$(dirname "$bin")/../../git/.githooks"
subject() {
  printf '%s\n' "$3" >"$tmp/msg"
  local got; (cd "$2" && sh "$hooks/commit-msg" "$tmp/msg" >/dev/null 2>&1)
  [[ $? == 0 ]] && got=allow || got=block
  [[ $got == "$1" ]] || { echo "✗ commit-msg: want $1, got $got: $3 in $2"; fail=1; }
}
git init -q "$W/cm" && git init -q "$tmp/plain"
subject allow "$W/cm" "PROJ-12 🐛 (fix): Handle null address"
subject allow "$W/cm" "♻️ (refactor): Split mapper"
subject allow "$W/cm" "Merge branch 'x'"
subject block "$W/cm" "fix: handle null address"
subject block "$W/cm" " (foo): Unknown category"
subject allow "$tmp/plain" "anything goes outside a delivery worktree"

g() { git -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@example.invalid "$@"; }
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
echo "✔ AI hooks: git-guard, leak-guard, commit-msg, and wt-prune behave"

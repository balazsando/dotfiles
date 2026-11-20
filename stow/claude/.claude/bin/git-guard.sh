#!/usr/bin/env bash
# PreToolUse (Claude) / beforeShellExecution (Cursor) hook enforcing the git contract:
# git writes run only inside a delivery worktree; --no-verify and plain --force never.
# Exit 2 blocks in both assistants; stderr reaches Claude, the JSON reaches Cursor.
set -uo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // .command // empty' <<<"$input" 2>/dev/null) || exit 0
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
[[ $cmd == *git* ]] || exit 0

root="${XDG_STATE_HOME:-$HOME/.local/state}/worktrees"
g='(^|[;&|(]|&&|\|\||\s)git(\s+-[cC]\s+\S+|\s+--\S+)*\s+'
write="${g}(commit|push|add|rm|reset|rebase|cherry-pick|revert|filter-branch|filter-repo|tag\s|update-ref|restore\s+(-S|--staged)|branch\s+(-[dDmMcCf]|--(delete|move|copy|force)|[^-[:space:]])|switch\s+(-[cC]|--create)|checkout\s+-[bB])"

deny() {
  printf 'git-guard: %s\n' "$1" >&2
  jq -cn --arg m "git-guard: $1" '{permission: "deny", user_message: $m, agent_message: $m}'
  exit 2
}

grep -qE -- "${g}.*--no-verify" <<<"$cmd" && deny "--no-verify is never allowed"
grep -qE -- "${g}push\b.*(\s-f\b|\s--force(\s|$))" <<<"$cmd" && deny "plain --force push is never allowed; use --force-with-lease after asking"

grep -qE -- "$write" <<<"$cmd" || exit 0
[[ $cmd == *"$root/"* || $cmd == *"/.local/state/worktrees/"* || $cwd == "$root/"* ]] && exit 0
deny "git writes run only in a delivery worktree under $root (change-delivery §3); run them as git -C <worktree>"

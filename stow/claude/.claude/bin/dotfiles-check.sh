#!/usr/bin/env bash
# Stop hook (Claude Stop, Cursor stop): when AI config under the dotfiles repo has uncommitted
# changes, run its parity and stow checks (and the hook self-check when a hook changed). A failure
# sends the output back to the agent: exit 2 for Claude, followup_message for Cursor.
set -uo pipefail

repo="${DOTFILES_DIR:-$HOME/dotfiles}"
input=$(cat)
[[ $(jq -r '(.stop_hook_active // false) or ((.loop_count // 0) > 0)' <<<"$input" 2>/dev/null) == true ]] && exit 0
dir=$(jq -r '.cwd // .workspace_roots[0]? // empty' <<<"$input" 2>/dev/null)
dir=$(realpath -m -- "${dir:-.}")
[[ $dir == "$repo" || $dir == "$repo/"* ]] || exit 0

changed=$(git -C "$repo" status --porcelain -- stow/claude stow/cursor stow/git 'check-ai-*.sh' 2>/dev/null)
[[ -n $changed ]] || exit 0

checks=("check-ai-parity.sh" "stow.sh -n")
grep -qE 'stow/(claude/\.claude/bin|git/\.githooks)/|check-ai-hooks' <<<"$changed" && checks+=("check-ai-hooks.sh")

# Only a failing check's output goes back: passing output is noise the agent pays for.
out=""
for c in "${checks[@]}"; do
  o=$(cd "$repo" && bash $c 2>&1) || out+="── $c
$o
"
done
[[ -z $out ]] && exit 0

msg="dotfiles checks failed — fix before finishing:
$out"
if [[ $(jq -r '.hook_event_name // empty' <<<"$input") == stop ]]; then
  jq -cn --arg m "$msg" '{followup_message: $m}'
  exit 0
fi
printf '%s\n' "$msg" >&2
exit 2

#!/usr/bin/env bash
# Blocks terms listed in ~/.claude/local/leak-terms.md from entering the public dotfiles repo.
#   leak-guard.sh           PreToolUse (Claude) / preToolUse Write (Cursor): JSON on stdin
#   leak-guard.sh --staged  pre-commit: the staged diff of the current repository
# One term per line, matched case-insensitively; blank lines and lines starting with # are
# ignored. Messages name the term's line number, never the term: scrollback is published too.
set -uo pipefail

terms_file="${LEAK_TERMS:-$HOME/.claude/local/leak-terms.md}"
repo="${DOTFILES_DIR:-$HOME/dotfiles}"

terms=$(grep -vE '^\s*(#|$)' "$terms_file" 2>/dev/null) || terms=""

if [[ ${1:-} == --staged ]]; then
  [[ $(git rev-parse --show-toplevel 2>/dev/null) == "$repo" ]] || exit 0
  [[ -n $terms ]] || { echo "leak-guard: $terms_file missing or empty, commit not checked" >&2; exit 0; }
  text=$(git diff --cached -U0 --no-color | grep -E '^\+' | grep -vE '^\+\+\+ ')
else
  input=$(cat)
  # Stowed files are edited through symlinks such as ~/.claude/…, so resolve before matching.
  path=$(jq -r '.tool_input.file_path? // .file_path? // empty' <<<"$input" 2>/dev/null)
  if [[ -n $path ]]; then
    [[ $(realpath -m -- "$path") == "$repo/"* ]] || exit 0
  else
    [[ $input == *"$repo/"* ]] || exit 0
  fi
  [[ -n $terms ]] || exit 0
  # Claude passes tool_input as an object: scan only the new text, so removing a term passes.
  if jq -e '.tool_input | type == "object"' <<<"$input" >/dev/null 2>&1; then
    text=$(jq -r '[.tool_input.content?, .tool_input.new_string?, (.tool_input.edits[]?.new_string?)]
                  | map(select(type == "string")) | join("\n")' <<<"$input")
  else
    text=$input
  fi
fi

hits=$(grep -nvE '^\s*(#|$)' "$terms_file" | while IFS= read -r line; do
  grep -qiF -- "${line#*:}" <<<"$text" && printf '%s ' "${line%%:*}"
done)
[[ -z $hits ]] && exit 0

msg="leak-guard: content matches $terms_file line(s) ${hits% }; reference the value (\$VAR or ~/.claude/local/<file>), never inline it"
printf '%s\n' "$msg" >&2
[[ ${1:-} == --staged ]] || jq -cn --arg m "$msg" '{permission: "deny", user_message: $m, agent_message: $m}'
exit 2

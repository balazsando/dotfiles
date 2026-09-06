#!/usr/bin/env bash
# check-ai-parity.sh — guard the Claude/Cursor sharing contract
#
# Cursor natively discovers ~/.claude/skills/ and ~/.claude/agents/ (compatibility paths,
# https://cursor.com/docs/skills). Skills and agents are therefore authored once, in
# stow/claude/.claude/, and must NOT exist under stow/cursor/.cursor/ — a same-named copy
# there takes precedence and silently shadows the shared original, reintroducing drift.
#
# Exit 1 and name the offenders if any skill or agent exists in the cursor tree.
# Called by stow.sh; also runnable standalone.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_TREE="$ROOT/stow/claude/.claude"
CURSOR_TREE="$ROOT/stow/cursor/.cursor"

violations=0
for layer in skills agents; do
  dir="$CURSOR_TREE/$layer"
  [[ -d "$dir" ]] || continue
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    if [[ -e "$CLAUDE_TREE/$layer/$entry" ]]; then
      echo "✗ $layer/$entry exists in both trees — the cursor copy shadows the shared claude one"
    else
      echo "✗ $layer/$entry lives under stow/cursor — skills and agents belong to stow/claude (shared)"
    fi
    violations=1
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null)
done

if [[ "$violations" -eq 1 ]]; then
  echo ""
  echo "Move the file(s) to stow/claude/.claude/ (Cursor discovers them from ~/.claude natively),"
  echo "then re-run. See README.md → Repository layout → AI assistant configs."
  exit 1
fi

echo "✔ AI config parity: no skills or agents under stow/cursor (shared from stow/claude)"

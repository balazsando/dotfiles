#!/usr/bin/env bash
# Applies the tracked AI settings. ~/.claude/settings.json is live state, so it is merged, never
# stowed: current ← ../settings.base.json ← ~/.claude/local/settings.local.json (machine-local keys,
# restored by bw-restore.sh). Then the marketplaces and plugins the base lists, and the Cursor hooks
# (ponytail, git-guard, leak-guard, dotfiles-check). Safe to re-run.
#   install-settings.sh [-n|--dry-run]
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base="$dir/../settings.base.json"
settings="$HOME/.claude/settings.json"
local_part="$HOME/.claude/local/settings.local.json"
cursor_hooks="$HOME/.cursor/hooks.json"
ponytail="$HOME/.local/share/ponytail"
dry=0
case ${1:-} in -n | --dry-run) dry=1 ;; "") ;; *) echo "usage: install-settings.sh [-n|--dry-run]" >&2; exit 1 ;; esac

for c in jq claude git; do command -v "$c" >/dev/null || { echo "error: $c not found on PATH" >&2; exit 1; }; done
[[ -f $base ]] || { echo "error: $base missing — is the claude package stowed?" >&2; exit 1; }

run() { if ((dry)); then echo "  → would run: $*"; else "$@"; fi; }

write_json() {
  local dest=$1 json=$2
  if [[ -f $dest ]] && jq -e --argjson n "$json" '. == $n' "$dest" >/dev/null 2>&1; then
    echo "  ✓ $dest up to date"; return
  fi
  if ((dry)); then echo "  → would update $dest"; return; fi
  mkdir -p "${dest%/*}"
  (umask 077; printf '%s\n' "$json" >"$dest.tmp") && mv "$dest.tmp" "$dest"
  echo "  ✓ $dest updated"
}

# Claude settings: deep merge, base then local win.
cur='{}'; [[ -f $settings ]] && cur=$(<"$settings")
loc='{}'; [[ -f $local_part ]] && loc=$(<"$local_part")
write_json "$settings" "$(jq -n --argjson c "$cur" --slurpfile b "$base" --argjson l "$loc" '$c * $b[0] * $l')"

# Marketplaces and plugins.
known=$(claude plugin marketplace list 2>/dev/null || true)
for m in $(jq -r '.extraKnownMarketplaces // {} | to_entries[] | "\(.key)=\(.value.source.repo)"' "$base"); do
  grep -q "❯ ${m%%=*}\$" <<<"$known" && echo "  ✓ marketplace ${m%%=*}" || run claude plugin marketplace add "${m#*=}"
done
installed=$(claude plugin list 2>/dev/null || true)
for p in $(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$base"); do
  grep -q "❯ $p\$" <<<"$installed" && echo "  ✓ plugin $p" || run claude plugin install "$p" --scope user
done

# Cursor: ponytail hooks from its own checkout, then ours merged beside them.
[[ -d $HOME/.cursor ]] || { echo "  – ~/.cursor missing — Cursor hooks skipped"; exit 0; }
if [[ -d $ponytail/.git ]]; then echo "  ✓ ponytail checkout"; else run git clone -q https://github.com/DietrichGebert/ponytail "$ponytail"; fi
if command -v node >/dev/null; then
  if ((dry)); then echo "  → would run: node $ponytail/scripts/cursor-hooks.js install"
  else node "$ponytail/scripts/cursor-hooks.js" install >/dev/null && echo "  ✓ ponytail Cursor hooks"; fi
else
  echo "  – node not on PATH — ponytail Cursor hooks skipped"
fi
hooks='{"version":1,"hooks":{}}'; [[ -f $cursor_hooks ]] && hooks=$(<"$cursor_hooks")
bin="$HOME/.claude/bin"
write_json "$cursor_hooks" "$(jq --arg b "$bin" '
  def add($ev; $h): if any(.hooks[$ev][]?; .command == $h.command) then . else .hooks[$ev] += [{timeout: 15} + $h] end;
  def q($s): "\"" + $b + "/" + $s + "\"";
  add("beforeShellExecution"; {command: q("git-guard.sh")})
  | add("beforeMCPExecution"; {command: q("git-guard.sh")})
  | add("preToolUse"; {command: q("leak-guard.sh"), matcher: "Write"})
  | add("stop"; {command: q("dotfiles-check.sh"), timeout: 120})
  | add("sessionStart"; {command: (q("wt-prune.sh") + " --hook")})' <<<"$hooks")"

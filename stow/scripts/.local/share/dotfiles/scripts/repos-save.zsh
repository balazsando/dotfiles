#!/usr/bin/env zsh
# repos-save.zsh — Walk $REPOS_DIR and write repos.txt with <rel-path>|<remote-url> entries.
# Run this before migrating to a new machine (called by sync.sh).

set -e
set -o pipefail

REPOS_DIR="${REPOS_DIR:-$HOME/repos}"
OUTPUT="${DOTFILES:-$HOME/dotfiles}/repos.txt"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""
fi

log_ok()   { print "  ${C_GREEN}✔ $*${C_RESET}"; }
log_warn() { print "  ${C_YELLOW}⚠ $*${C_RESET}"; }
log_info() { print "  ${C_CYAN}• $*${C_RESET}"; }

if [[ ! -d "$REPOS_DIR" ]]; then
  log_warn "REPOS_DIR not found: $REPOS_DIR — skipping repos save"
  exit 0
fi

print "▶ Scanning repos in $REPOS_DIR"

# Load existing entries keyed by rel-path so we preserve known URLs
typeset -A existing_entries
if [[ -f "$OUTPUT" ]]; then
  while IFS='|' read -r rel remote; do
    [[ -z "$rel" || "$rel" == \#* ]] && continue
    existing_entries[$rel]="$remote"
  done < "$OUTPUT"
fi

# Collect entries discovered from the filesystem
typeset -A discovered_entries
while IFS= read -r git_dir; do
  repo_dir="${git_dir:h}"
  rel="${repo_dir#$REPOS_DIR/}"

  remote=$(git -C "$repo_dir" remote get-url origin 2>/dev/null) || {
    log_warn "No remote 'origin' in $repo_dir — skipping"
    continue
  }

  discovered_entries[$rel]="$remote"
done < <(find "$REPOS_DIR" -maxdepth 3 -name ".git" -type d | sort)

# Merge: start from existing, add only newly discovered entries
typeset -A merged_entries
for rel in "${(@k)existing_entries}"; do
  merged_entries[$rel]="${existing_entries[$rel]}"
done

added=0
for rel in "${(@k)discovered_entries}"; do
  if [[ -z "${merged_entries[$rel]}" ]]; then
    merged_entries[$rel]="${discovered_entries[$rel]}"
    log_info "NEW  $rel  →  ${discovered_entries[$rel]}"
    added=$((added + 1))
  fi
done

# Write sorted merged output
{
  for rel in "${(@ko)merged_entries}"; do
    print "$rel|${merged_entries[$rel]}"
  done
} > "$OUTPUT"

total=${#merged_entries}
kept=$((total - added))
log_ok "repos.txt: $kept kept, $added new — $total total → $OUTPUT"

# Upload is intentionally NOT done here. sync.sh calls bw-upload.zsh directly
# straight after this script; doing it here as well uploaded every secret twice
# per sync. bw-upload.zsh is the single upload entry point.

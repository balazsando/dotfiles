#!/usr/bin/env bash
# repos-restore.sh — Clone repos listed in repos.txt into $REPOS_DIR.
# Silently skips repos that already exist or fail (VPN-gated repos).
# Format of repos.txt: <relative-path-from-REPOS_DIR>|<remote-url>

REPOS_DIR="${REPOS_DIR:-$HOME/repos}"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
REPOS_FILE="$DOTFILES/repos.txt"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""
fi

log_ok()   { printf '%s\n' "  ${C_GREEN}✔ $*${C_RESET}"; }
log_warn() { printf '%s\n' "  ${C_YELLOW}⚠ $*${C_RESET}"; }
log_skip() { printf '%s\n' "  ${C_YELLOW}⊘ $*${C_RESET}"; }
log_info() { printf '%s\n' "  ${C_CYAN}• $*${C_RESET}"; }

# repos.txt comes from bw-restore.sh ("dotfiles/repos"), which install.sh runs
# long before this script. Fetching it here as well was a second, independent
# Bitwarden code path; bw-restore.sh is now the single restore entry point.
if [[ ! -f "$REPOS_FILE" ]]; then
  log_warn "repos.txt not found at $REPOS_FILE — skipping restore"
  log_info "Restore it with: bash ~/.local/share/dotfiles/scripts/bw-restore.sh"
  exit 0
fi

printf '▶ Restoring repos to %s\n' "$REPOS_DIR"

_clone_repo() {
  local rel="$1" remote="$2"
  local local_path="$REPOS_DIR/$rel"

  if [[ -d "$local_path/.git" ]]; then
    log_skip "$rel (already exists)"
    return 0
  fi

  mkdir -p "$(dirname "$local_path")"
  log_info "Cloning $rel ..."
  if git clone "$remote" "$local_path" 2>/dev/null; then
    log_ok "$rel"
  else
    log_warn "$rel — clone failed (VPN required or unreachable)"
  fi
}

while IFS='|' read -r rel remote; do
  [[ -z "$rel" || "$rel" == \#* ]] && continue
  _clone_repo "$rel" "$remote" &
done < "$REPOS_FILE"

wait

echo ""
log_ok "Repo restore complete"

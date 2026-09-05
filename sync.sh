#!/usr/bin/env zsh
# sync.sh — Pre-migration export script.
# Run this on the current machine BEFORE bootstrapping a new environment.
# Exports: wsl.conf (WSL only), repo list, Bitwarden secrets/certs/kube.

set -e
set -o pipefail

# Self-locating so the repo works from any clone location.
export DOTFILES="${DOTFILES:-${0:A:h}}"
SCRIPTS_DIR="$DOTFILES/stow/scripts/.local/share/dotfiles/scripts"
# shellcheck source=stow/scripts/.local/share/dotfiles/scripts/wsl-detect.sh
source "$SCRIPTS_DIR/wsl-detect.sh"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""
fi

log_ok()   { print "  ${C_GREEN}✔ $*${C_RESET}"; }
log_warn() { print "  ${C_YELLOW}⚠ $*${C_RESET}"; }
log_step() { print "\n${C_BOLD}▶ $*${C_RESET}"; }

print "${C_BOLD}dotfiles — sync (pre-migration export)${C_RESET}"

# ── WSL: sync /etc/wsl.conf → dotfiles ──────────────────────────────────────
if is_wsl; then
  log_step "Syncing wsl.conf"
  zsh "$SCRIPTS_DIR/wslconf-sync.zsh"
else
  log_warn "Not WSL — skipping wsl.conf sync"
fi

# ── Save repo list ────────────────────────────────────────────────────────────
log_step "Saving repository list"
zsh "$SCRIPTS_DIR/repos-save.zsh"

# ── Upload secrets / certs / kube to Bitwarden ───────────────────────────────
log_step "Uploading secrets to Bitwarden"
zsh "$SCRIPTS_DIR/bw-upload.zsh"

# ── Remind user to commit ────────────────────────────────────────────────────
print ""
print "${C_BOLD}${C_YELLOW}⚠  Don't forget to commit changes:${C_RESET}"
print "   cd $DOTFILES"
print "   git add -A"
print "   git commit -m 'chore: pre-migration sync'"
print "   git push"
print ""
log_ok "Sync complete"

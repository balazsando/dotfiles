#!/usr/bin/env zsh
set -e
set -o pipefail

source "${DOTFILES:-$HOME/dotfiles}/stow/scripts/.local/share/dotfiles/scripts/wsl-detect.sh"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""
fi

log_ok()   { print "  ${C_GREEN}✔ $*${C_RESET}"; }
log_warn() { print "  ${C_YELLOW}⚠ $*${C_RESET}"; }

# Only makes sense inside WSL
if ! is_wsl; then
  log_warn "Not running inside WSL — skipping wsl.conf sync"
  exit 0
fi

SRC="/etc/wsl.conf"
DST="${DOTFILES:-$HOME/dotfiles}/host/wsl.conf"

if [[ ! -f "$SRC" ]]; then
  log_warn "/etc/wsl.conf does not exist — nothing to sync"
  exit 0
fi

if [[ -f "$DST" ]] && diff -q "$SRC" "$DST" >/dev/null 2>&1; then
  log_ok "wsl.conf already up to date in dotfiles"
else
  cp "$SRC" "$DST"
  log_ok "Synced /etc/wsl.conf → $DST"
  log_warn "Remember to: cd ${DOTFILES:-$HOME/dotfiles} && git add wsl.conf && git commit -m 'chore: sync wsl.conf'"
fi

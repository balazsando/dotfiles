#!/usr/bin/env bash
# bw-restore.sh — Restore sensitive dotfiles secrets from Bitwarden
#
# Restores:
#   ~/.config/zsh/secrets                    ← "dotfiles/zsh_secrets"
#   ~/.config/git/credentials                ← "dotfiles/git-credentials"
#   ~/.kube/config-*.yml, config-*.yaml      ← "dotfiles/kube/<filename>"
#   ~/certs/*.crt, *.pem                     ← "dotfiles/certs/<filename>"
#   $DOTFILES/repos.txt                      ← "dotfiles/repos"
#
# NOTE: The main ~/.kube/config file is NOT restored (only additional configs).
# All files and directories are optional. If any are missing, they are skipped.
# Optionally installs certificates into the system trust store.
#
# Requirements: bw (Bitwarden CLI), jq
# Run this script early on a new machine, before or after running install.sh.

set -e
set -o pipefail
shopt -s nullglob   # Don't expand glob patterns if no matches

umask 077

# Prefer the real CA. The bypass is only for a genuinely fresh machine: the CA
# that would validate this is itself in the vault, so on first run there is no
# ordering that avoids it.
source "$(dirname "${BASH_SOURCE[0]}")/node-ca.sh"
if node_ca_setup; then
  _tls_mode="verified (~/certs)"
else
  export NODE_TLS_REJECT_UNAUTHORIZED=0
  _tls_mode="UNVERIFIED — no local CA yet, bootstrapping"
fi
export PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.npm-global/bin"

# ─── Colors ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""
fi

log_step() { printf '\n%s\n' "${C_BOLD}${C_CYAN}▶ $*${C_RESET}"; }
log_ok()   { printf '%s\n'   "  ${C_GREEN}✔ $*${C_RESET}"; }
log_warn() { printf '%s\n'   "  ${C_YELLOW}⚠ $*${C_RESET}"; }
log_err()  { printf '%s\n'   "  ${C_RED}✘ $*${C_RESET}"; }

# ─── Dependency check ────────────────────────────────────────────────────────
for dep in bw jq; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    log_err "$dep is required but not installed"
    log_err "Install it first: npm install -g @bitwarden/cli"
    exit 1
  fi
done

# ─── Bitwarden auth ──────────────────────────────────────────────────────────
bw_ensure_unlocked() {
  # Fast path: if session is already set and vault reports unlocked, skip prompts
  if [[ -n "${BW_SESSION:-}" ]]; then
    local status
    status=$(bw status --session "$BW_SESSION" 2>/dev/null | jq -r '.status' 2>/dev/null) || status=""
    if [[ "$status" == "unlocked" ]]; then
      log_ok "Vault already unlocked (session reused)"
      return 0
    fi
  fi

  local bw_status
  bw_status=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null) || bw_status=""
  if [[ -z "$bw_status" || "$bw_status" == "null" ]]; then
    log_err "Could not read Bitwarden status. Try: bw login   (or: unset BW_SESSION)"
    bw status || true
    exit 1
  fi

  case "$bw_status" in
    unauthenticated)
      log_step "Logging in to Bitwarden"
      # --raw returns the session, so this does not prompt for the password twice.
      local session
      if session=$(bw login --raw); then
        export BW_SESSION="$session"
        log_ok "Logged in and unlocked"
      else
        log_err "Login failed"
        exit 1
      fi
      ;;
    locked)
      log_step "Unlocking Bitwarden vault"
      local session
      session=$(bw unlock --raw)
      export BW_SESSION="$session"
      log_ok "Vault unlocked"
      ;;
    unlocked)
      log_ok "Vault already unlocked"
      ;;
    *)
      log_err "Unknown Bitwarden status: $bw_status"
      exit 1
      ;;
  esac
}

bw_get_note() {
  local name="$1"
  local content
  content=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .notes // empty' "$_bw_cache")
  [[ -n "$content" ]] || return 1
  printf '%s' "$content"
}

# ─── Fetch vault once ────────────────────────────────────────────────────────
# Holds the whole vault in plaintext — private, and removed on exit.
_bw_cache="$(mktemp -t bw-items.XXXXXXXXXX)"
chmod 600 "$_bw_cache"
trap 'rm -f "$_bw_cache"' EXIT INT TERM HUP

bw_fetch_all() {
  log_step "Fetching Bitwarden items"
  bw list items --session "$BW_SESSION" >"$_bw_cache"
  [[ -s "$_bw_cache" ]] || {
    log_err "Failed to fetch Bitwarden items"
    exit 1
  }
  log_ok "Vault items loaded"
}

# ─── Restore a note to a local file ──────────────────────────────────────────
bw_restore_file() {
  local name="$1"
  local dest="$2"
  local mode="${3:-600}"

  local content
  if ! content=$(bw_get_note "$name"); then
    log_warn "Not found in Bitwarden: $name — skipping"
    return 0
  fi

  # Expand notes stored compressed by bw-upload.zsh.
  if [[ "$content" == '#gz#'* ]]; then
    content=$(printf '%s' "${content#\#gz\#}" | tr -d '\n' | base64 -d | gunzip) || {
      log_err "Failed to decompress $name"; return 1; }
  fi

  mkdir -p "$(dirname "$dest")"

  # Validate PEM content for cert files
  if [[ "$dest" == *.crt || "$dest" == *.pem ]]; then
    if ! printf '%s' "$content" | grep -q -- '-----BEGIN'; then
      log_warn "Skipping $dest — content is not a valid PEM block (partial download?)"
      return 0
    fi
  fi

  if [[ -f "$dest" && "$(<"$dest")" == "$content" ]]; then
    chmod "$mode" "$dest"
    log_ok "Unchanged: $dest"
    return 0
  fi

  printf '%s\n' "$content" > "$dest"
  chmod "$mode" "$dest"
  log_ok "Restored: $dest"
}

# BW_SESSION is deliberately not persisted — it would be a durable unlock key,
# stored inside the vault it unlocks. Use: export BW_SESSION=$(bw unlock --raw)

# ─── Install certs to system trust store ─────────────────────────────────────
install_certs_to_trust_store() {
  local cert_dir="$HOME/certs"

  if command -v update-ca-certificates >/dev/null 2>&1; then
    # Debian / Ubuntu / WSL2
    (
      shopt -s nullglob
      for cert in "$cert_dir"/*.crt "$cert_dir"/*.pem; do
        [[ -f "$cert" ]] || continue
        sudo cp "$cert" "/usr/local/share/ca-certificates/$(basename "$cert")"
      done
    )
    sudo update-ca-certificates
    log_ok "System trust store updated (Debian/Ubuntu)"
  elif command -v update-ca-trust >/dev/null 2>&1; then
    # Arch / Fedora / RHEL
    (
      shopt -s nullglob
      for cert in "$cert_dir"/*.crt "$cert_dir"/*.pem; do
        [[ -f "$cert" ]] || continue
        sudo cp "$cert" "/etc/ca-certificates/trust-source/anchors/$(basename "$cert")"
      done
    )
    sudo update-ca-trust extract
    log_ok "System trust store updated (Arch/Fedora)"
  else
    log_warn "No update-ca-certificates or update-ca-trust found — install certs manually"
  fi
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
  printf '%s\n' "${C_BOLD}bw-restore — restoring dotfiles secrets from Bitwarden${C_RESET}"
  printf '%s\n' "  TLS: $_tls_mode"

  bw_ensure_unlocked

  log_step "Syncing vault"
  if bw sync --session "$BW_SESSION" >/dev/null 2>&1; then
    log_ok "Vault synced"
  else
    log_warn "Vault sync failed — continuing with cached data"
  fi

  bw_fetch_all

  bw_restore_file "dotfiles/repos" "${DOTFILES:-$HOME/dotfiles}/repos.txt" 600 &
  bw_restore_file "dotfiles/git-credentials" "$HOME/.config/git/credentials" 600 &

  mkdir -p "$HOME/.kube"
  log_step "Restoring kube configs"

  local -a kube_names
  mapfile -t kube_names < <(jq -r '
    .[] | select(.name | startswith("dotfiles/kube/")) | .name
  ' "$_bw_cache")

  for item in "${kube_names[@]}"; do
    bw_restore_file "$item" "$HOME/.kube/${item#dotfiles/kube/}" 600 &
  done

  mkdir -p "$HOME/certs"
  log_step "Restoring certificates"

  local -a cert_names
  mapfile -t cert_names < <(jq -r '
    .[] | select(.name | startswith("dotfiles/certs/")) | .name
  ' "$_bw_cache")

  for item in "${cert_names[@]}"; do
    bw_restore_file "$item" "$HOME/certs/${item#dotfiles/certs/}" 644 &
  done

  bw_restore_file "dotfiles/zsh_secrets" "$HOME/.config/zsh/secrets" 600 &

  # Must stay in */local/ — ~/.claude and ~/.cursor hold stow symlinks into the
  # repo, so writing elsewhere puts this content back in the working tree.
  log_step "Restoring AI overlay"

  local -a ai_names
  mapfile -t ai_names < <(jq -r '
    .[] | select(.name | startswith("dotfiles/ai/")) | .name
  ' "$_bw_cache")

  if (( ${#ai_names[@]} == 0 )); then
    log_warn "No dotfiles/ai/* items in the vault — agents run without work context"
  else
    mkdir -p "$HOME/.claude/local" "$HOME/.cursor/local"
    for item in "${ai_names[@]}"; do
      local _leaf="${item#dotfiles/ai/}"
      bw_restore_file "$item" "$HOME/.claude/local/$_leaf" 644 &
      bw_restore_file "$item" "$HOME/.cursor/local/$_leaf" 644 &
    done
  fi

  wait

  if compgen -G "$HOME/certs/*.crt" >/dev/null 2>&1 || \
     compgen -G "$HOME/certs/*.pem" >/dev/null 2>&1; then
    log_step "Installing certificates"
    install_certs_to_trust_store
  fi

  printf '\n%s\n' "${C_BOLD}${C_GREEN}✔ Restore complete!${C_RESET}"
}

main "$@"

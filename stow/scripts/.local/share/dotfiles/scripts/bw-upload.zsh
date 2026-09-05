#!/usr/bin/env zsh
# bw-upload.zsh — Upload sensitive dotfiles secrets to Bitwarden
#
# Uploads the following as Bitwarden secure notes (upsert — safe to re-run):
#   ~/.zsh_secrets                           → "dotfiles/zsh_secrets"
#   ~/.git-credentials                       → "dotfiles/git-credentials"
#   ~/.kube/config-*.yml, config-*.yaml      → "dotfiles/kube/<filename>"
#   ~/certs/*.crt, *.pem                     → "dotfiles/certs/<filename>"
#
# NOTE: The main ~/.kube/config file is NOT uploaded (only additional configs).
# All files and directories are optional. If any are missing, they are skipped.
# Requirements: bw (Bitwarden CLI), jq
# The BW_SESSION env var is used if already set; otherwise the vault is unlocked interactively.

set -e
set -o pipefail
setopt nullglob   # Don't expand glob patterns if no matches

source "${0:A:h}/node-ca.sh"
node_ca_setup || true

# ─── Colors ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""
fi

log_step() { print "\n${C_BOLD}${C_CYAN}▶ $*${C_RESET}"; }
log_ok()   { print "  ${C_GREEN}✔ $*${C_RESET}"; }
log_warn() { print "  ${C_YELLOW}⚠ $*${C_RESET}"; }
log_err()  { print "  ${C_RED}✘ $*${C_RESET}"; }
log_skip() { print "  ${C_YELLOW}⊘ $*${C_RESET}"; }

# ─── Dependency check ────────────────────────────────────────────────────────
for dep in bw jq; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    log_err "$dep is required but not installed"
    exit 1
  fi
done

# ─── Bitwarden auth ──────────────────────────────────────────────────────────
bw_ensure_unlocked() {
  local session
  if [[ -n "${BW_SESSION:-}" ]]; then
    local state
    state=$(bw status --session "$BW_SESSION" 2>/dev/null | jq -r '.status' 2>/dev/null) || state=""
    if [[ "$state" == "unlocked" ]]; then
      log_ok "Vault already unlocked (session reused)"
      return 0
    fi
  fi

  local bw_status
  bw_status=$(bw status | jq -r '.status')

  case "$bw_status" in
    unauthenticated)
      log_step "Logging in to Bitwarden"
      session=$(bw login --raw)
      export BW_SESSION="$session"
      log_ok "Logged in"
      ;;
    locked)
      log_step "Unlocking Bitwarden vault"
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

# ─── Upsert a secure note ────────────────────────────────────────────────────
# Usage: bw_upsert_note <item-name> <file-path>
bw_upsert_note() {
  local name="$1"
  local file="$2"

  if [[ ! -f "$file" ]]; then
    log_warn "File not found, skipping: $file"
    return 0
  fi

  # Bitwarden caps the ENCRYPTED note at 10000 chars, and base64 inflates by ~4/3.
  # Compress anything near the ceiling; bw-restore.sh expands the #gz# marker.
  local src="$file" tmp=""
  if (( $(stat -c%s "$file") > 6500 )); then
    tmp=$(mktemp); { print -r -- '#gz#'; gzip -9 -c "$file" | base64 -w0 } >"$tmp"
    src="$tmp"
  fi

  local id json cached
  id=$(jq -r --arg n "$name" 'first(.[] | select(.name == $n) | .id) // empty' "$_bw_cache")

  if [[ -n "$id" ]]; then
    # Content already cached from the single list call — skip untouched files
    # rather than paying two bw round-trips to rewrite identical bytes.
    cached=$(jq -r --arg n "$name" 'first(.[] | select(.name == $n) | .notes) // ""' "$_bw_cache")
    if [[ "$cached" == "$(<"$src")" ]]; then
      [[ -n "$tmp" ]] && rm -f "$tmp"
      log_skip "Unchanged: $name"
      return 0
    fi
    json=$(bw get item "$id" --session "$BW_SESSION" | jq --rawfile notes "$src" '.notes = $notes')
    bw edit item "$id" "$(print -rn -- "$json" | base64 -w0)" --session "$BW_SESSION" >/dev/null
    log_ok "Updated: $name${tmp:+ (compressed)}"
  else
    json=$(jq -n --arg name "$name" --rawfile notes "$src" \
      '{type: 2, name: $name, notes: $notes, secureNote: {type: 0}}')
    bw create item "$(print -rn -- "$json" | base64 -w0)" --session "$BW_SESSION" >/dev/null
    log_ok "Created: $name${tmp:+ (compressed)}"
  fi
  [[ -n "$tmp" ]] && rm -f "$tmp"
  return 0
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
  print "${C_BOLD}bw-upload — uploading dotfiles secrets to Bitwarden${C_RESET}"

  bw_ensure_unlocked

  log_step "Syncing vault"
  bw sync --session "$BW_SESSION" >/dev/null || log_warn "Sync failed — using cached vault"
  log_ok "Vault synced"

  log_step "Fetching item list"
  _bw_cache=$(mktemp -t bw-items.XXXXXX)
  chmod 600 "$_bw_cache"
  trap 'rm -f "$_bw_cache"' EXIT INT TERM HUP
  bw list items --session "$BW_SESSION" >"$_bw_cache"
  log_ok "$(jq length "$_bw_cache") item(s)"

  # ── certificates ────────────────────────────────────────────────────────
  if [[ -d "$HOME/certs" ]]; then
    log_step "Uploading certificates from $HOME/certs/"
    local cert_count=0
    for cert in "$HOME/certs"/*.crt "$HOME/certs"/*.pem; do
      [[ -f "$cert" ]] || continue
      local cert_name="dotfiles/certs/$(basename "$cert")"
      bw_upsert_note "$cert_name" "$cert"
      cert_count=$((cert_count + 1))
    done
    if (( cert_count == 0 )); then
      log_warn "No .crt/.pem files found in $HOME/certs/ — skipping"
    else
      log_ok "$cert_count certificate(s) uploaded"
    fi
  else
    log_warn "~/certs/ not found — skipping certificates"
  fi

  # ── repos list ──────────────────────────────────────────────────────────
  log_step "Uploading repos.txt"
  if [[ -f "${DOTFILES:-$HOME/dotfiles}/repos.txt" ]]; then
    bw_upsert_note "dotfiles/repos" "${DOTFILES:-$HOME/dotfiles}/repos.txt"
  else
    log_warn "repos.txt not found — skipping"
  fi

  # ── .zsh_secrets ─────────────────────────────────────────────────────────
  log_step "Uploading ~/.config/zsh/secrets"
  if [[ -f "$HOME/.config/zsh/secrets" ]]; then
    bw_upsert_note "dotfiles/zsh_secrets" "$HOME/.config/zsh/secrets"
  else
    log_warn "~/.zsh_secrets not found — skipping"
  fi

  # ── .git-credentials ─────────────────────────────────────────────────────
  log_step "Uploading ~/.config/git/credentials"
  if [[ -f "$HOME/.config/git/credentials" ]]; then
    bw_upsert_note "dotfiles/git-credentials" "$HOME/.config/git/credentials"
  else
    log_warn "~/.git-credentials not found — skipping"
  fi

  # ── AI overlay ───────────────────────────────────────────────────────────
  # ~/.cursor/local is restored from the same items, so one side is enough.
  if [[ -d "$HOME/.claude/local" ]]; then
    log_step "Uploading AI overlay from ~/.claude/local/"
    local ai_count=0
    for ai_file in "$HOME/.claude/local"/*.md; do
      [[ -f "$ai_file" ]] || continue
      bw_upsert_note "dotfiles/ai/$(basename "$ai_file")" "$ai_file"
      ai_count=$((ai_count + 1))
    done
    (( ai_count == 0 )) && log_warn "No .md files in ~/.claude/local/ — skipping"
  else
    log_warn "~/.claude/local/ not found — skipping AI overlay"
  fi

  # ── kube configs ─────────────────────────────────────────────────────────
  if [[ -d "$HOME/.kube" ]]; then
    log_step "Uploading additional kube configs from ~/.kube/"
    local kube_count=0
    # Upload only config-*.yml / config-*.yaml files (skip main config)
    for kube_file in "$HOME/.kube/config-"*.yml "$HOME/.kube/config-"*.yaml; do
      [[ -f "$kube_file" ]] || continue
      local kube_item_name="dotfiles/kube/$(basename "$kube_file")"
      bw_upsert_note "$kube_item_name" "$kube_file"
      kube_count=$((kube_count + 1))
    done
    if (( kube_count == 0 )); then
      log_warn "No additional kube configs found in ~/.kube/ — skipping"
    else
      log_ok "$kube_count additional kube config(s) uploaded"
    fi
  else
    log_warn "~/.kube/ not found — skipping kube configs"
  fi 

  print "\n${C_BOLD}${C_GREEN}✔ Upload complete!${C_RESET}"
  print "  Items stored as Bitwarden secure notes under the ${C_CYAN}dotfiles/${C_RESET} prefix."
  print "  Run ${C_CYAN}scripts/bw-restore.zsh${C_RESET} on a new machine to restore them."
}

main "$@"

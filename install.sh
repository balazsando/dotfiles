#!/usr/bin/env bash
# install.sh — Dotfiles bootstrap for Debian/Ubuntu
# Usage: bash install.sh [--dry-run]
# Safe to re-run — every step is guarded.

set -euo pipefail

export DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
step() { echo -e "\n${BOLD}${CYAN}▶ $*${RESET}"; }
ok()   { echo -e "  ${GREEN}✔ $*${RESET}"; }
skip() { echo -e "  ${YELLOW}⊘ $*${RESET} (already present)"; }
has()  { command -v "$1" >/dev/null 2>&1; }
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && { DRY_RUN=true; echo -e "${YELLOW}▶ DRY RUN${RESET}\n"; }
run() { $DRY_RUN && echo "  → $*" || "$@"; }

echo -e "${BOLD}dotfiles bootstrap — Debian${RESET}"

# ── 1. APT packages ───────────────────────────────────────────────────────────
step "APT packages"
run sudo apt-get update -qq
run sudo apt-get install -y --no-install-recommends \
  $(grep -v '^#\|^[[:space:]]*$' "$DOTFILES/packages/apt.txt" | tr '\n' ' ')
ok "apt packages"

# ── 2. WSL PATH guard (prevents Windows bw.exe shadowing Linux bw) ────────────
step "WSL PATH"
# shellcheck source=stow/scripts/.local/share/dotfiles/scripts/wsl-detect.sh
source "$DOTFILES/stow/scripts/.local/share/dotfiles/scripts/wsl-detect.sh"
needs_fix=false
while IFS= read -r e; do
  [[ "$e" != /mnt/c/* ]] && continue
  case "${e,,}" in
    /mnt/c/windows/system32|/mnt/c/windows/system32/*) ;;
    *) needs_fix=true; break ;;
  esac
done <<<"${PATH//:/$'\n'}"
if $needs_fix; then
  sudo cp "$DOTFILES/host/wsl.conf" /etc/wsl.conf
  echo -e "\n❗ Windows PATH detected — restart required: wsl --shutdown"
  [[ -n "${WSL_DISTRO_NAME:-}" ]] && exit 1
fi
ok "WSL PATH clean"

# ── 3. BW CLI (installed early — secrets include corporate VPN certs) ─────────
step "Bitwarden CLI"
if ! has bw; then
  run mkdir -p "$HOME/.npm-global"
  run npm config set prefix "$HOME/.npm-global"
  export PATH="$HOME/.npm-global/bin:$PATH"
  run npm install -g --silent @bitwarden/cli tree-sitter-cli
fi
ok "bw, tree-sitter-cli"

# ── 4. Secrets + VPN certs (NODE_TLS_REJECT_UNAUTHORIZED=0 scoped to BW only) ─
step "Bitwarden secrets"
if [[ -f "$HOME/.config/zsh/secrets" && -f "$HOME/.config/git/credentials" ]]; then
  skip "secrets already present"
elif $DRY_RUN; then
  echo "  → would prompt: Restore secrets from Bitwarden? [y/N]"
else
  read -rp "  Restore secrets from Bitwarden? [y/N] " _bw_reply
  if [[ "${_bw_reply,,}" == "y" ]]; then
    export NODE_TLS_REJECT_UNAUTHORIZED=0
    bash "$DOTFILES/stow/scripts/.local/share/dotfiles/scripts/bw-restore.sh" || true
    unset NODE_TLS_REJECT_UNAUTHORIZED
    run sudo update-ca-certificates
    source "$HOME/.config/zsh/secrets"
    ok "secrets + certs"
  fi
fi

# ── 5. Oh-My-Zsh + plugins ────────────────────────────────────────────────────
step "Oh-My-Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  if $DRY_RUN; then
    echo "  → would install Oh-My-Zsh"
  else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi
  ok "Oh-My-Zsh"
else
  skip "Oh-My-Zsh"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
_clone_plugin() {
  local repo="${1%% *}" target="${1#* }"
  [[ -d "$ZSH_CUSTOM/$target" ]] && { echo "  ⊘ $(basename "$target") (already present)"; return; }
  run git clone --depth=1 "https://github.com/$repo" "$ZSH_CUSTOM/$target" \
    && ok "$(basename "$target")"
}
_clone_plugin "zsh-users/zsh-autosuggestions plugins/zsh-autosuggestions" &
_clone_plugin "zsh-users/zsh-syntax-highlighting plugins/zsh-syntax-highlighting" &
_clone_plugin "romkatv/powerlevel10k themes/powerlevel10k" &
wait

# ── 6. GitHub binary installs ─────────────────────────────────────────────────
step "GitHub binaries"
# Bump both together for a newer build.
JIRLAB_COMMIT="9687157457747d5ec8e11dc1f2836e93b0b0149f"
JIRLAB_SHA256="a4b9ece41791e2e8a49462b2a9541524782a9b40073af2ef77782f90029dece4"
if $DRY_RUN; then
  echo "  → would fetch jirlab @ ${JIRLAB_COMMIT:0:7} and verify sha256"
elif ! has jirlab; then
  tmp=$(mktemp)
  curl -fsSLo "$tmp" \
    "https://github.com/balazsando/jirlab/raw/$JIRLAB_COMMIT/bin/jirlab"
  if ! echo "$JIRLAB_SHA256  $tmp" | sha256sum -c --status -; then
    rm -f "$tmp"
    echo "  ✗ jirlab checksum mismatch — refusing to install" >&2
    echo "    expected $JIRLAB_SHA256" >&2
    exit 1
  fi
  chmod +x "$tmp"
  run sudo mv "$tmp" /usr/local/bin/jirlab
  ok "jirlab (verified)"
else
  skip "jirlab"
fi

# ── 6b. cursor-agent ──────────────────────────────────────────────────────────
step "cursor-agent"
# Not npm — the npm package of that name is an unrelated third-party project.
if $DRY_RUN; then
  echo "  → would install cursor-agent"
elif ! has cursor-agent && [[ ! -x "$HOME/.local/bin/cursor-agent" ]]; then
  sh -c "$(curl -fsSL https://cursor.com/install)"
  ok "cursor-agent"
else
  skip "cursor-agent"
fi

# ── 7. Default shell → zsh ────────────────────────────────────────────────────
step "Default shell"
_zsh="$(command -v zsh || true)"
if [[ -n "$_zsh" && "${SHELL:-}" != "$_zsh" ]]; then
  # $USER is set by login/PAM but not by e.g. `docker run`, and set -u makes
  # that fatal — id -un always works.
  run sudo chsh -s "$_zsh" "${USER:-$(id -un)}" && ok "default shell → zsh"
else
  skip "default shell already zsh"
fi

# ── 8. mise + all tools ───────────────────────────────────────────────────────
step "mise"
if $DRY_RUN; then
  echo "  → would install mise"
elif ! has mise && [[ ! -x "$HOME/.local/bin/mise" ]]; then
  curl -fsSL https://mise.run | sh
  ok "mise installed"
else
  skip "mise ($(mise --version 2>/dev/null))"
fi
export PATH="$HOME/.local/bin:$PATH"
if ! $DRY_RUN; then
  cd "$DOTFILES/stow/mise"
  mise trust
  eval "$(mise activate bash)"
  mise install
  npm config set prefix "$HOME/.npm-global"
  ok "tools installed via mise"
fi

# ── 9. GNU Stow ───────────────────────────────────────────────────────────────
step "GNU Stow"
run bash "$DOTFILES/stow.sh"
run mise trust "$HOME/.mise.toml" 2>/dev/null || true

# ── 10. tmux TPM ──────────────────────────────────────────────────────────────
step "tmux TPM"
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  run mkdir -p "$HOME/.tmux/plugins"
  run git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ok "tmux TPM"
else
  skip "tmux TPM"
fi

# ── 11. Git identity ──────────────────────────────────────────────────────────
step "Git identity"

_write_git_identity() {
  cat >"$HOME/.gitconfig_local" <<EOF
[user]
    name  = $GIT_USER_NAME
    email = $GIT_USER_EMAIL
EOF
  chmod 600 "$HOME/.gitconfig_local"
  ok "~/.gitconfig_local written"
}

# Kept out of the versioned .gitconfig. Added idempotently so existing machines
# get it too, rather than silently losing git auth for non-`gh` hosts.
_ensure_credential_helper() {
  local f="$HOME/.gitconfig_local"
  [[ -f "$f" ]] || return 0
  grep -q '^\[credential\]' "$f" && return 0
  cat >>"$f" <<'EOF'

[credential]
    helper = store --file ~/.config/git/credentials
EOF
  ok "credential helper added to ~/.gitconfig_local"
}

if [[ -f "$HOME/.gitconfig_local" ]] || $DRY_RUN; then
  skip "~/.gitconfig_local"
  $DRY_RUN || _ensure_credential_helper
else
  if [[ ! -f "$HOME/.config/zsh/secrets" ]]; then
    read -rp "  Git user name:  " GIT_USER_NAME
    read -rp "  Git user email: " GIT_USER_EMAIL
    mkdir -p "$HOME/.config/zsh"
    cat >"$HOME/.config/zsh/secrets" <<EOF
export GIT_USER_NAME="$GIT_USER_NAME"
export GIT_USER_EMAIL="$GIT_USER_EMAIL"
# export JIRA_URL=""
# export JIRA_EMAIL=""
# export JIRA_TOKEN=""
EOF
    chmod 600 "$HOME/.config/zsh/secrets"
    ok "~/.config/zsh/secrets created"
  fi
  set +u
  # shellcheck disable=SC1091
  source "$HOME/.config/zsh/secrets"
  set -u
  _write_git_identity
  _ensure_credential_helper
fi

# ── 11b. MCP server registration ──────────────────────────────────────────────
step "MCP servers"
# ~/.claude.json is live runtime state, so register via the CLI, not stow.
_mcp_install="$HOME/.claude/bin/install-mcp-servers.sh"
if $DRY_RUN; then
  echo "  → would register MCP servers from ~/.claude/mcp-servers.json"
elif ! has claude; then
  skip "claude CLI not installed — MCP registration"
elif [[ -x "$_mcp_install" ]]; then
  bash "$_mcp_install" || echo "  ⚠ MCP registration failed — re-run: $_mcp_install"
else
  skip "install-mcp-servers.sh not stowed yet"
fi

# ── 12. Post-install ──────────────────────────────────────────────────────────
step "Post-install"

if ! $DRY_RUN; then
  bash "$DOTFILES/stow/scripts/.local/share/dotfiles/scripts/addcerts.sh" \
    || echo "  ⚠ some certificates were not imported — re-run: addcerts"
fi

_nvim="$(mise which nvim 2>/dev/null || command -v nvim 2>/dev/null || true)"
if $DRY_RUN; then
  echo "  → would sync Neovim plugins and install tmux plugins"
elif [[ -n "$_nvim" && -x "$_nvim" && -f "$HOME/.config/nvim/init.lua" ]]; then
  TERM=xterm-256color "$_nvim" --headless "+Lazy! sync" +qa 2>&1 | tail -5 || true
  ok "Neovim plugins synced"
else
  echo "  ⊘ nvim not ready — skipping plugin sync"
fi

_tpm="$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
if ! $DRY_RUN && [[ -f "$_tpm" ]] && [[ -f "$HOME/.config/tmux/tmux.conf" || -L "$HOME/.config/tmux/tmux.conf" ]]; then
  tmux start-server 2>/dev/null || true
  tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null || true
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" bash "$_tpm" 2>&1 | tail -5 || true
  ok "tmux plugins installed"
fi

_repos="$DOTFILES/repos.txt"
_restore="$DOTFILES/stow/scripts/.local/share/dotfiles/scripts/repos-restore.sh"
if [[ -f "$_repos" ]] && [[ -f "$_restore" ]]; then
  run bash "$_restore" || true
  ok "repos restored"
fi

echo -e "\n${BOLD}${GREEN}✔ Bootstrap complete!${RESET}"

_missing=()
[[ -f "$HOME/.config/zsh/secrets"     ]] || _missing+=("~/.config/zsh/secrets (tokens, work config)")
[[ -f "$HOME/.config/git/credentials" ]] || _missing+=("~/.config/git/credentials")
compgen -G "$HOME/certs/*.crt"     >/dev/null 2>&1 || _missing+=("~/certs/ (corporate CA)")
compgen -G "$HOME/.kube/config-*"  >/dev/null 2>&1 || _missing+=("~/.kube/config-* (cluster access)")
compgen -G "$HOME/.claude/local/*.md" >/dev/null 2>&1 || _missing+=("~/.claude/local/ (AI work context)")

if (( ${#_missing[@]} )); then
  echo -e "\n  ${YELLOW}⚠ Not restored from Bitwarden:${RESET}"
  printf '      • %s\n' "${_missing[@]}"
  echo -e "    The shell and tooling work without these. To fetch them:"
  echo -e "      ${CYAN}bash ~/.local/share/dotfiles/scripts/bw-restore.sh${RESET}"
fi

echo -e "\n  Run ${CYAN}exec zsh${RESET} to start your new shell."
echo -e "  Or: ${CYAN}mise run sync${RESET} to pull updates and restow."

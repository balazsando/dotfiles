#!/usr/bin/env bash
# install.sh — Dotfiles bootstrap for Debian/Ubuntu/WSL2
# Usage: bash install.sh [--dry-run]   Safe to re-run — every step is guarded.

set -euo pipefail

export DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES/stow/scripts/.local/share/dotfiles/scripts"
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
step() { echo -e "\n${BOLD}${CYAN}▶ $*${RESET}"; }
ok()   { echo -e "  ${GREEN}✔ $*${RESET}"; }
skip() { echo -e "  ${YELLOW}⊘ $*${RESET}"; }
has()  { command -v "$1" >/dev/null 2>&1; }
list() { grep -v '^#\|^[[:space:]]*$' "$DOTFILES/packages/$1" || true; }
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && { DRY_RUN=true; echo -e "${YELLOW}▶ DRY RUN${RESET}"; }
run() { if $DRY_RUN; then echo "  → $*"; else "$@"; fi; }
curl_pipe() { run bash -o pipefail -c "curl -fsSL '$1' | $2"; }

echo -e "${BOLD}dotfiles bootstrap — Debian${RESET}"

# ── 1. APT ────────────────────────────────────────────────────────────────────
step "APT packages"
mapfile -t apt_pkgs < <(list apt.txt)
run sudo apt-get update -qq
run sudo apt-get install -y --no-install-recommends "${apt_pkgs[@]}"
ok "apt packages"

# ── 2. WSL PATH guard ─────────────────────────────────────────────────────────
step "WSL PATH"
source "$SCRIPTS/wsl-detect.sh"
if is_wsl && printf %s "$PATH" | awk -v RS=: '
  { p = tolower($0) } p ~ /^\/mnt\/c\// && p !~ /^\/mnt\/c\/windows\/system32(\/|$)/ { f = 1 }
  END { exit !f }'; then
  run sudo cp "$DOTFILES/host/wsl.conf" /etc/wsl.conf
  echo -e "\n❗ Windows PATH detected — run: wsl --shutdown, then re-run install.sh"
  $DRY_RUN || exit 1
fi
ok "WSL PATH clean"

# ── 3. Bitwarden CLI ──────────────────────────────────────────────────────────
step "Bitwarden CLI"
run npm config set prefix "$HOME/.npm-global"
if has bw; then skip "bw"; else run npm install -g --silent @bitwarden/cli; ok "bw"; fi
if has tree-sitter; then skip "tree-sitter-cli"; else run npm install -g --silent tree-sitter-cli; ok "tree-sitter-cli"; fi

# ── 4. Secrets + certs ────────────────────────────────────────────────────────
step "Bitwarden secrets"
if [[ -f "$HOME/.config/zsh/secrets" && -f "$HOME/.config/git/credentials" ]]; then
  skip "secrets"
elif $DRY_RUN; then
  echo "  → would offer to run bw-restore.sh"
else
  read -rp "  Restore secrets from Bitwarden? [y/N] " reply
  if [[ "${reply,,}" == "y" ]]; then
    export NODE_TLS_REJECT_UNAUTHORIZED=0
    bash "$SCRIPTS/bw-restore.sh" && ok "secrets + certs" ||
      echo "  ⚠ restore failed — re-run: bash $SCRIPTS/bw-restore.sh"
    unset NODE_TLS_REJECT_UNAUTHORIZED
  fi
fi

# ── 5. Oh-My-Zsh ──────────────────────────────────────────────────────────────
step "Oh-My-Zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  skip "Oh-My-Zsh"
else
  curl_pipe https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh 'sh -s -- --unattended'
  ok "Oh-My-Zsh"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for p in plugins:zsh-users/zsh-autosuggestions plugins:zsh-users/zsh-syntax-highlighting themes:romkatv/powerlevel10k; do
  repo="${p#*:}" dir="$ZSH_CUSTOM/${p%%:*}/${p##*/}"
  if [[ -d "$dir" ]]; then skip "${p##*/}"; else run git clone -q --depth=1 "https://github.com/$repo" "$dir" && ok "${p##*/}"; fi &
done
wait

# ── 6. GitHub binaries ────────────────────────────────────────────────────────
step "GitHub binaries"
# Bump both together for a newer build.
JIRLAB_COMMIT="9687157457747d5ec8e11dc1f2836e93b0b0149f"
JIRLAB_SHA256="a4b9ece41791e2e8a49462b2a9541524782a9b40073af2ef77782f90029dece4"
if has jirlab; then
  skip "jirlab"
elif $DRY_RUN; then
  echo "  → would fetch jirlab @ ${JIRLAB_COMMIT:0:7} and verify sha256"
else
  tmp=$(mktemp)
  curl -fsSLo "$tmp" "https://github.com/balazsando/jirlab/raw/$JIRLAB_COMMIT/bin/jirlab"
  echo "$JIRLAB_SHA256  $tmp" | sha256sum -c --status - ||
    { rm -f "$tmp"; echo "  ✗ jirlab checksum mismatch — refusing to install" >&2; exit 1; }
  sudo install -m 755 "$tmp" /usr/local/bin/jirlab && rm -f "$tmp"
  ok "jirlab (verified)"
fi
if has cursor-agent; then
  skip "cursor-agent"
else
  curl_pipe https://cursor.com/install sh
  ok "cursor-agent"
fi

# ── 7. Default shell ──────────────────────────────────────────────────────────
step "Default shell"
zsh_bin="$(command -v zsh || true)"
if [[ -z "$zsh_bin" || "${SHELL:-}" == "$zsh_bin" ]]; then
  skip "default shell"
else
  run sudo chsh -s "$zsh_bin" "$(id -un)" && ok "default shell → zsh"
fi

# ── 8. mise ───────────────────────────────────────────────────────────────────
step "mise"
if has mise; then skip "mise"; else curl_pipe https://mise.run sh; ok "mise"; fi
if ! $DRY_RUN; then
  cd "$DOTFILES/stow/mise"
  mise trust
  mise install
  eval "$(mise activate bash)"
  ok "tools installed via mise"
fi

# ── 9. SDKMAN ─────────────────────────────────────────────────────────────────
step "SDKMAN"
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
  skip "SDKMAN"
else
  curl_pipe 'https://get.sdkman.io?rcupdate=false' bash
  ok "SDKMAN"
fi
sdk_install() {
  run bash -c 'source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install "$@"' _ "$@" &&
    ok "$*" || echo "  ⚠ sdk install $* failed — re-run it in a new shell"
}
JAVA_MAJOR=21
if [[ -e "$HOME/.sdkman/candidates/java/current" ]]; then
  skip "java"
else
  java_id="$(curl -fsSL 'https://api.sdkman.io/2/candidates/java/linuxx64/versions/list?installed=' |
    grep -oE "\b$JAVA_MAJOR\.[0-9.+]*-tem\b" | sort -uV | tail -1 || true)"
  if [[ -n "$java_id" ]]; then sdk_install java "$java_id"; else echo "  ⚠ no Temurin $JAVA_MAJOR found — run: sdk install java"; fi
fi
if [[ -e "$HOME/.sdkman/candidates/maven/current" ]]; then skip "maven"; else sdk_install maven; fi

# ── 10. Stow ──────────────────────────────────────────────────────────────────
step "GNU Stow"
run bash "$DOTFILES/stow.sh"
run mise trust "$HOME/.mise.toml" 2>/dev/null || true

# ── 11. tmux TPM ──────────────────────────────────────────────────────────────
step "tmux TPM"
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  skip "tmux TPM"
else
  run git clone -q --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ok "tmux TPM"
fi

# ── 12. Git identity ──────────────────────────────────────────────────────────
step "Git identity"
secrets="$HOME/.config/zsh/secrets" gitlocal="$HOME/.gitconfig_local"
if $DRY_RUN; then
  echo "  → would ensure ~/.gitconfig_local (user + credential helper)"
else
  if [[ -f "$gitlocal" ]]; then
    skip "~/.gitconfig_local"
  else
    if [[ ! -f "$secrets" ]]; then
      read -rp "  Git user name:  " GIT_USER_NAME
      read -rp "  Git user email: " GIT_USER_EMAIL
      mkdir -p "${secrets%/*}"
      (umask 077; printf 'export GIT_USER_NAME="%s"\nexport GIT_USER_EMAIL="%s"\n' \
        "$GIT_USER_NAME" "$GIT_USER_EMAIL" >"$secrets")
      ok "~/.config/zsh/secrets created"
    fi
    set +u; source "$secrets"; set -u
    [[ -n "${GIT_USER_NAME:-}" ]] || read -rp "  Git user name:  " GIT_USER_NAME
    [[ -n "${GIT_USER_EMAIL:-}" ]] || read -rp "  Git user email: " GIT_USER_EMAIL
    (umask 077; printf '[user]\n    name  = %s\n    email = %s\n' \
      "$GIT_USER_NAME" "$GIT_USER_EMAIL" >"$gitlocal")
    ok "~/.gitconfig_local written"
  fi
  if ! grep -q '^\[credential\]' "$gitlocal"; then
    printf '\n[credential]\n    helper = store --file ~/.config/git/credentials\n' >>"$gitlocal"
    ok "credential helper added to ~/.gitconfig_local"
  fi
fi

# ── 13. MCP servers ───────────────────────────────────────────────────────────
step "MCP servers"
CBM_TAG="v0.11.0"
CBM_COMMIT="8972ea69c6ad94b1ef1d4ffbf0a92d78d2db1798"
CBM_SHA256="13049c7cc51bc508d68b8ecb8a9fd9574ecb7c6f2c9dd5a19bf7d4c187321145"
if has codebase-memory-mcp; then
  skip "codebase-memory-mcp"
elif $DRY_RUN; then
  echo "  → would fetch the codebase-memory-mcp $CBM_TAG installer and verify sha256"
else
  tmp=$(mktemp)
  curl -fsSLo "$tmp" "https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/$CBM_COMMIT/install.sh"
  echo "$CBM_SHA256  $tmp" | sha256sum -c --status - ||
    { rm -f "$tmp"; echo "  ✗ codebase-memory-mcp installer checksum mismatch — refusing to install" >&2; exit 1; }
  CBM_DOWNLOAD_URL="https://github.com/DeusData/codebase-memory-mcp/releases/download/$CBM_TAG" \
    SHELL=/bin/sh bash "$tmp" --clients=claude
  rm -f "$tmp"
  ok "codebase-memory-mcp $CBM_TAG (verified)"
fi
mcp_install="$HOME/.claude/bin/install-mcp-servers.sh"
if ! has claude || [[ ! -x "$mcp_install" ]]; then
  skip "claude CLI or install-mcp-servers.sh missing — MCP registration"
else
  run bash "$mcp_install" || echo "  ⚠ MCP registration failed — re-run: $mcp_install"
fi

# ── 14. uv tools ──────────────────────────────────────────────────────────────
step "uv tools"
if ! has uv; then
  skip "uv not on PATH — uv tools"
else
  uv_installed="$(uv tool list 2>/dev/null || true)"
  while IFS= read -r tool; do
    name="${tool%%\[*}"
    if grep -q "^$name " <<<"$uv_installed"; then skip "$name"; else run uv tool install -q "$tool" && ok "$name"; fi
  done < <(list uv-tools.txt)
fi

# ── 15. Post-install ──────────────────────────────────────────────────────────
step "Post-install"
run bash "$SCRIPTS/addcerts.sh" || echo "  ⚠ some certificates were not imported — re-run: addcerts"

nvim_bin="$(mise which nvim 2>/dev/null || command -v nvim || true)"
if [[ -x "$nvim_bin" && -f "$HOME/.config/nvim/init.lua" ]]; then
  run env TERM=xterm-256color "$nvim_bin" --headless "+Lazy! sync" +qa 2>&1 | tail -5 || true
  ok "Neovim plugins synced"
else
  skip "nvim not ready — plugin sync"
fi

tpm="$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
if ! $DRY_RUN && [[ -f "$tpm" && -e "$HOME/.config/tmux/tmux.conf" ]]; then
  tmux start-server 2>/dev/null || true
  tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null || true
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" bash "$tpm" 2>&1 | tail -5 || true
  ok "tmux plugins installed"
fi

if [[ -f "$DOTFILES/repos.txt" ]]; then
  run bash "$SCRIPTS/repos-restore.sh" || true
fi

echo -e "\n${BOLD}${GREEN}✔ Bootstrap complete!${RESET}"

missing=()
[[ -f "$HOME/.config/zsh/secrets" ]]                  || missing+=("~/.config/zsh/secrets (tokens, work config)")
[[ -f "$HOME/.config/git/credentials" ]]              || missing+=("~/.config/git/credentials")
compgen -G "$HOME/certs/*.crt" >/dev/null             || missing+=("~/certs/ (corporate CA)")
compgen -G "$HOME/.kube/config-*" >/dev/null          || missing+=("~/.kube/config-* (cluster access)")
compgen -G "$HOME/.claude/local/*.md" >/dev/null      || missing+=("~/.claude/local/ (AI work context)")
if (( ${#missing[@]} )); then
  echo -e "\n  ${YELLOW}⚠ Not restored from Bitwarden:${RESET}"
  printf '      • %s\n' "${missing[@]}"
  echo -e "    The shell and tooling work without these. To fetch them:"
  echo -e "      ${CYAN}bash ~/.local/share/dotfiles/scripts/bw-restore.sh${RESET}"
fi

echo -e "\n  Run ${CYAN}exec zsh${RESET} to start your new shell, or ${CYAN}mise run sync${RESET} to pull and restow."

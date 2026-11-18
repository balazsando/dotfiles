# JIRA_* lives in ~/.config/zsh/secrets — the ids and workflow names are
# organization-specific and must not be tracked here.

# --- Environment ---
export ZSH="$HOME/.oh-my-zsh"
export GOPATH="$HOME/go"
export REPOS_DIR="$HOME/repos"
export EDITOR=nvim
export VISUAL=nvim
export GLOW_STYLE="$HOME/.config/glow/catppuccin-mocha.json"
export K9S_SKIN=catppuccin-mocha-transparent
export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=0
[[ -n "$GITLAB_API_URL" ]] && export GITLAB_HOST=${${GITLAB_API_URL#*://}%%/*}

# --- Node TLS ---
# Node ignores the OS trust store, so the corporate chain must be passed
# explicitly. Rebuild the ~/certs bundle here and export NODE_EXTRA_CA_CERTS:
# node tooling and the MCP servers launched from this shell both inherit it.
if [[ -r "$HOME/.local/share/dotfiles/scripts/node-ca.sh" ]]; then
  source "$HOME/.local/share/dotfiles/scripts/node-ca.sh"
  node_ca_setup || true
fi

# --- PATH ---
export JAVA_HOME="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/current"
export PATH="$JAVA_HOME/bin:$HOME/.local/share/nvim/mason/packages/jdtls:$HOME/.npm-global/bin:$GOPATH/bin:$HOME/.local/bin:$PATH"
[[ -d /mnt/c/Windows/System32/WindowsPowerShell/v1.0 ]] && path+=(/mnt/c/Windows/System32/WindowsPowerShell/v1.0)

# --- fzf ---
export FZF_DEFAULT_OPTS="
--height=85%
--layout=reverse
--border
--info=inline
--preview-window=right:60%:wrap
--bind=ctrl-u:preview-half-page-up
--bind=ctrl-d:preview-half-page-down
"

[[ -S /mnt/wslg/runtime-dir/wayland-0 && ! -e /run/user/$UID/wayland-0 ]] &&
  ln -sfn /mnt/wslg/runtime-dir/wayland-0 /run/user/$UID/wayland-0
[[ -S /mnt/wslg/.X11-unix/X0 && ! -e /tmp/.X11-unix/X0 ]] &&
  ln -sfn /mnt/wslg/.X11-unix/X0 /tmp/.X11-unix/X0

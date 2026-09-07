# JIRA_* lives in ~/.config/zsh/secrets — the ids and workflow names are
# organization-specific and must not be tracked here.

# --- Environment ---
export ZSH="$HOME/.oh-my-zsh"
export GOPATH="$HOME/go"
export REPOS_DIR="$HOME/repos"
export EDITOR=nvim
export VISUAL=nvim

# --- Agent token tooling ---
export GRAPHIFY_HOOK_STRICT=0

# --- Node TLS ---
# Node ignores the OS trust store, so the corporate chain must be passed
# explicitly. Rebuild the ~/certs bundle here and export NODE_EXTRA_CA_CERTS:
# node tooling and the MCP servers launched from this shell both inherit it.
if [[ -r "$HOME/.local/share/dotfiles/scripts/node-ca.sh" ]]; then
  source "$HOME/.local/share/dotfiles/scripts/node-ca.sh"
  node_ca_setup || true
fi

# --- PATH ---
export PATH="$HOME/.npm-global/bin:$GOPATH/bin:$HOME/.local/bin:$PATH"

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

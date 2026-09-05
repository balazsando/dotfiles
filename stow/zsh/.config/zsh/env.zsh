# JIRA_* lives in ~/.config/zsh/secrets — the ids and workflow names are
# organization-specific and must not be tracked here.

# --- Environment ---
export ZSH="$HOME/.oh-my-zsh"
export GOPATH="$HOME/go"
export REPOS_DIR="$HOME/repos"
export EDITOR=nvim
export VISUAL=nvim

# --- Node TLS ---
# Node ignores the OS trust store. Bundle is built from ~/certs by node-ca.sh.
[[ -f "$HOME/.cache/dotfiles/ca-bundle.pem" ]] \
  && export NODE_EXTRA_CA_CERTS="$HOME/.cache/dotfiles/ca-bundle.pem"

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

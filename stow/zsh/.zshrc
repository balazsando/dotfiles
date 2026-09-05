# --- Powerlevel10k Instant Prompt ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

alias v="nvim"
alias vim="nvim"

# --- mise ---
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$($HOME/.local/bin/mise activate zsh)"
fi

# --- Sensitive Tokens ---
[[ -f ~/.config/zsh/secrets ]] && source ~/.config/zsh/secrets

# --- Environment Variables ---
source ~/.config/zsh/env.zsh

# --- Oh My Zsh Core Config ---
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git docker kubectl zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# --- Aliases & Functions ---
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/functions.zsh
source ~/.config/zsh/relocate.zsh

# --- External Sources ---
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ -f "$HOME/.config/envman/load.sh" ]] && source "$HOME/.config/envman/load.sh"
command -v fzf >/dev/null && source <(fzf --zsh)

# --- Misc ---
eval "$(zoxide init zsh)"
typeset -U path

# --- Auto-start tmux for interactive non-SSH shells ---
if command -v tmux >/dev/null 2>&1; then
  if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ -z "$SSH_TTY" ]]; then
    tmux attach 2>/dev/null || tmux
  fi
fi

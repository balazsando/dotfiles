# --- Powerlevel10k Instant Prompt ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- mise ---
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$($HOME/.local/bin/mise activate zsh)"
fi

# --- Sensitive Tokens ---
[[ -f ~/.config/zsh/secrets ]] && source ~/.config/zsh/secrets
[[ -f ~/.config/zsh/local.zsh ]] && source ~/.config/zsh/local.zsh

# --- Environment Variables ---
source ~/.config/zsh/env.zsh

# --- Oh My Zsh Core Config ---
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git kubectl zsh-autosuggestions zsh-syntax-highlighting sudo)
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

# --- Auto-start tmux for interactive non-SSH shells; the main session only where local.zsh sets TMUX_MAIN=1 ---
if command -v tmux >/dev/null 2>&1; then
  if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ -z "$SSH_TTY" ]]; then
    if [[ ${TMUX_MAIN:-0} == 1 ]]; then ~/.local/share/dotfiles/scripts/tmux-main.sh attach; else tmux; fi
  fi
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

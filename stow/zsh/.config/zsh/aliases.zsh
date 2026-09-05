#!/usr/bin/env zsh
# --- Aliases ---
alias ai='cursor-agent'
alias aig='gh copilot'
alias d="docker"
alias k="kubectl"
alias kctx="kubectx"
alias kd="kubectl describe"
alias kgp="kubectl get pods"
alias kns="kubens"
alias ld='lazydocker'
alias lf='lfcd'
alias lg='lazygit'
alias l="eza -l --icons --git -a"
alias ls="eza --icons --group-directories-first --color=auto --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias mk="minikube"
alias mkdb='minikube dashboard'
alias mke='eval $(minikube docker-env)'
alias mkeoff='eval $(minikube docker-env -u)'
alias mks='minikube start'
alias mkst='minikube stop'
alias mkt='minikube tunnel'
alias pimp='nvim ~/.zshrc'
alias re='source ~/.zshrc'
alias wslconf-sync='zsh ~/.local/share/dotfiles/scripts/wslconf-sync.zsh'
alias jl='jirlab board'

# --- Work / project aliases --- ($WIN_USER from ~/.config/zsh/secrets)
# The kubeconfig-switching aliases live in ~/.config/zsh/secrets — the config
# filenames map out the cluster layout.
alias go-pwsh='make build-powershell && f=$(ls *.exe 2>/dev/null | head -n1); [ -n "$f" ] && mv -v "$f" /mnt/c/Users/$WIN_USER/bin/'
alias hinst='helm install shopstream ./helm/shopstream'
alias hupd='helm upgrade shopstream ~/repos/practice/pet-proj-1/helm/shopstream --set global.imageTag=latest'
alias mkcert='for c in /mnt/c/Users/$WIN_USER/certs/*.crt; do minikube cp "$c" /usr/local/share/ca-certificates/extra/$(basename "$c"); done && minikube ssh "sudo update-ca-certificates && sudo systemctl restart containerd && sudo systemctl restart docker || true"'
alias pet='cd ~/repos/practice/pet-proj-1/'

# --- VS Code (WSL) ---
alias code='"/mnt/c/Program Files/Microsoft VS Code/bin/code"'

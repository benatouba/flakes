export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

alias vim="nvim"
alias cat='bat'
alias grep='rg'
alias ca='clear && fastfetch'
alias grname='git config --get remote.origin.url'
alias gpab='git branch -r | grep -v "\->" | while read remote; do git branch --track "${remote#origin/}" "$remote"; done'
alias isntall='install'

alias -g zshrc='~/.zshrc'

# suffix aliases
alias -s {json,yml,yaml,css,js,ts,html,py,txt,md,lua}=vim

alias mkdir="mkdir -pv"

alias uppnpm="pnpm -g update"
alias up="nh os switch ~/projects/flakes"
alias ref="source ~/.zshrc"

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

function nvimvenv {
  if [[ -e "$VIRTUAL_ENV" && -f "$VIRTUAL_ENV/bin/activate" ]]; then
    source "$VIRTUAL_ENV/bin/activate"
    command nvim "$@"
    deactivate
  else
    command nvim "$@"
  fi
}
alias nvim=nvimvenv

alias uppnpm="pnpm -g update"
alias up="sudo nixos-rebuild switch --flake ~/projects/flakes#laptop"
alias ref="source ~/.zshrc"

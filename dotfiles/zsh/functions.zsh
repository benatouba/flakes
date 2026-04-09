function _git_status {
    zle kill-whole-line
    zle -U "git status"
    zle accept-line
}
zle -N _git_status

function _explorer {
    zle kill-whole-line
    zle -U "$EXPLORER"
    zle accept-and-hold
}
zle -N _explorer

function printColors() {
  for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}

function tarPackUnpack() {
  case "$1" in
    pack)
      echo "packing $2"
      tar cfzv "$2.tar.gz" $2
      ;;
    unpack)
      echo "unpacking $2"
      tar xfvz "$2.tar.gz"
      ;;
    *)
      echo "Usage: $0 pack|unpack"
      ;;
  esac
}

function zrc () {
    $EDITOR ~/.zshrc && source $_
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

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

# sshd() { TERM=xterm-256color command ssh "$@"; }

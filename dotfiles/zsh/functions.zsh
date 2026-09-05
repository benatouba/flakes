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

# Wrap ssh to repair the terminal and reconnect when a connection drops.
#
# A remote tmux, editor or pager arms terminal modes over the SSH pipe — mouse
# tracking, focus reporting, the alternate screen — that only it can disarm. If
# the link dies instead of exiting cleanly, those modes stay armed on the local
# terminal and every mouse move floods the prompt with escape junk.
#
# Ported from Omarchy's bash version. Only interactive shells load this file,
# so scripts calling ssh are unaffected.
function _ssh_disarm() {
  # Mouse tracking (1000/1002/1003 and the 1006 encoding), focus reporting
  # (1004), the alternate screen (1049), then show the cursor again.
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1004l\e[?1049l\e[?25h'
}

# True for an interactive session: a destination and no remote command. The
# letters are the ssh(1) options that take a value, so their arguments are not
# mistaken for the destination.
function _ssh_interactive() {
  local value_opts="BbcDEeFIiJLlmOoPpQRSWw"
  local arg letters dest="" opts_done=""
  local -a original=("$@")
  local i

  while (( $# )); do
    arg="$1"
    shift

    if [[ -z $opts_done && $arg == "--" ]]; then
      opts_done=1
    elif [[ -z $opts_done && $arg == -?* ]]; then
      letters="${arg#-}"
      for (( i = 0; i < ${#letters}; i++ )); do
        if [[ $value_opts == *"${letters:$i:1}"* ]]; then
          # The value is glued to the letter (-p2222) unless the letter ends
          # the argument, in which case it consumes the next one (-p 2222).
          (( i == ${#letters} - 1 )) && shift
          break
        fi
      done
    elif [[ -z $dest ]]; then
      dest="$arg"
    else
      return 1
    fi
  done

  [[ -n $dest ]] || return 1

  # A RemoteCommand from ssh_config or -o replays on reconnect exactly like a
  # positional command would. `ssh -G` resolves the effective config for this
  # invocation without connecting. Fail closed if it cannot resolve: an
  # undetected RemoteCommand must not be replayed.
  local resolved
  resolved=$(command ssh -G "${original[@]}" 2>/dev/null) || return 1
  ! grep -i '^remotecommand ' <<<"$resolved" | grep -qvi '^remotecommand none$'
}

function ssh() {
  local rc started
  started=$SECONDS
  command ssh "$@"
  rc=$?

  [[ -t 1 ]] || return $rc
  _ssh_disarm

  # Reconnect only when an established interactive session drops. ssh exits
  # 255 for transport failures, but a fast 255 with no session is a connect or
  # auth failure, a remote command's own 255 is indistinguishable and must not
  # have its side effects replayed, and a redirected stdin would feed the rest
  # of the piped input to a fresh remote shell.
  if (( rc != 255 )) || [[ ! -t 0 ]] || ! _ssh_interactive "$@" \
    || (( SECONDS - started < 30 )); then
    return $rc
  fi

  # Retry in a subshell so Ctrl-C reaches the whole foreground process group
  # and cancels both the in-flight attempt and the loop. Keep retrying fast
  # failures too: a rebooting server refuses connections before it accepts.
  (
    while true; do
      echo "Connection lost. Reconnecting (Ctrl-C to stop)..."
      sleep 2
      command ssh "$@"
      rc=$?
      _ssh_disarm
      (( rc != 255 )) && exit $rc
    done
  )
}

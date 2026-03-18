
# User exports
export BROWSER='brave'
export MANPAGER="nvim +Man!"
export COLORSCHEME="catppuccin-macchiato"
export PATH="$PATH:${HOME}/.cargo/bin:${HOME}/.local/bin"
export DOTF="$HOME/projects/flakes/dotfiles"
export NVIM_DIR="$XDG_CONFIG_HOME/nvim"
export EDITOR='nvim'
export EXPLORER='yazi'
export DEFAULT_USER="$USER"
export RIPGREP_CONFIG_PATH="$HOME/projects/flakes/dotfiles/rgrc"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"

export TIME_STYLE="iso"
export TEXMFHOME="$HOME/.local/share/texmf"
export HYPRSHOT_DIR="$HOME/pictures/screenshots/"

# pnpm
export PNPM_HOME="${HOME}/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


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

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"

export TIME_STYLE="iso"
export TEXMFHOME="$HOME/.local/share/texmf"

# Drop the legacy pnpm setup directory, including when inherited from an old
# session. Home Manager manages PNPM_HOME and adds PNPM_HOME/bin for global tools.
path=("${(@)path:#${HOME}/.local/share/pnpm}")

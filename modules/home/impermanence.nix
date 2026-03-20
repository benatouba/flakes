{
  config,
  lib,
  pkgs,
  user,
  ...
}:
{
  home.persistence."/persist" = {
    directories = [
      # Projects (includes nvim config + flakes)
      "projects"

      # Browsers
      ".mozilla"
      ".config/BraveSoftware"

      # programs state
      ".local/state"

      # Neovim state
      ".local/share/nvim"

      # Shell history & state
      ".local/share/zoxide" # zoxide directory database

      # Tmux plugins (tpm bootstraps here)
      ".tmux"

      # Credentials & security
      ".ssh"
      ".gnupg"
      ".secrets" # tokens.zsh and other secrets
      ".local/secrets" # nix build-time secrets (mail accounts, etc.)

      # User data dirs (lowercase) — downloads intentionally excluded (wiped each boot)
      "documents"
      "music"
      "pictures"
      "videos"

      # Python / uv
      ".cache/uv" # downloaded wheels & packages
      ".local/share/uv" # managed toolchains

      # Node / pnpm
      ".local/share/pnpm"

      # Music
      ".local/share/mpd"

      # Bitwarden (Electron desktop app)
      ".config/Bitwarden"

      # Keyrings
      ".local/share/keyrings"

      # Obsidian
      ".config/obsidian"

      # OBS Studio
      ".config/obs-studio"

      # Claude Code
      ".claude"

      # GitHub Copilot (neovim auth tokens)
      ".config/github-copilot"

      # Zoom
      ".zoom"

      # Nix
      ".cache/nix"

      # direnv (nix-direnv cached dev shells)
      ".local/share/direnv"

      # devenv global state
      ".local/share/devenv"

      # Mail (mbsync Maildir)
      "mail"

      # GTK bookmarks & settings
      ".config/gtk-3.0"
      ".config/gtk-4.0"
    ];

  };
}

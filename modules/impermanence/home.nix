{ config, lib, pkgs, user, ... }:
{
  home.persistence."/persist" = {
    directories = [
      # Projects (includes nvim config + flakes)
      "projects"

      # Browsers
      ".mozilla"
      ".config/BraveSoftware"

      # Neovim state
      ".local/share/nvim"
      ".local/state/nvim"

      # Shell history & state
      ".local/share/zoxide"           # zoxide directory database

      # Tmux plugins (tpm bootstraps here)
      ".tmux"

      # Credentials & security
      ".ssh"
      ".gnupg"
      ".secrets"                      # tokens.zsh and other secrets

      # User data dirs (lowercase) — downloads intentionally excluded (wiped each boot)
      "documents"
      "music"
      "pictures"
      "videos"

      # Python / uv
      ".cache/uv"                     # downloaded wheels & packages
      ".local/share/uv"              # managed toolchains

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

      # Zoom
      ".zoom"

      # Nix
      ".cache/nix"

      # Zsh state (history, compdump)
      ".local/state/zsh"

      # GTK bookmarks & settings
      ".config/gtk-3.0"
      ".config/gtk-4.0"
    ];

};
}

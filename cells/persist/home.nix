{ ... }:
{
  config.my.hmModules = [{
    home.persistence."/persist" = {
      directories = [
        "projects"
        ".mozilla"
        ".config/BraveSoftware"
        ".local/state"
        ".local/share/nvim"
        ".local/share/zoxide"
        ".tmux"
        ".ssh"
        ".gnupg"
        ".secrets"
        ".local/secrets"
        "documents"
        "music"
        "pictures"
        "videos"
        ".cache/uv"
        ".local/share/uv"
        ".local/share/pnpm"
        ".local/share/mpd"
        ".config/Bitwarden"
        ".local/share/keyrings"
        ".config/obsidian"
        ".config/obs-studio"
        ".claude"
        ".config/opencode"
        ".config/github-copilot"
        ".config/gh"
        ".zoom"
        ".cache/nix"
        ".local/share/direnv"
        ".local/share/devenv"
        "mail"
        ".config/gtk-3.0"
        ".config/gtk-4.0"
      ];
    };
  }];
}

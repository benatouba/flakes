_: {
  config.my.branches.persist.hmModules = [
    ({ config, lib, ... }: {
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
          # rbw device ID, API-key registration and encrypted vault cache; without
          # it every boot is a "new device" for Bitwarden.
          ".local/share/rbw"
          ".config/obsidian"
          ".config/obs-studio"
          ".claude"
          ".config/opencode"
          ".config/github-copilot"
          ".config/gh"
          ".railway"
          ".zoom"
          ".cache/nix"
          ".cache/Cypress"
          ".cache/ms-playwright"
          ".cache/opencode"
          ".cache/BraveSoftware"
          ".npm"
          ".local/share/direnv"
          ".local/share/devenv"
          "mail"
          ".config/gtk-3.0"
          ".config/gtk-4.0"
          # LibreOffice user profile (registrymodifications.xcu); without it,
          # preferences such as "Show tips on startup" reset on every boot.
          ".config/libreoffice"
          ".local/share/atuin"
          ".local/share/nix-index"
          ".local/share/opencode"
        ]
        ++ lib.optionals config.programs.qutebrowser.enable [
          # Local profile only: cookies, site storage, history and explicit
          # sessions/permissions. HTTP cache stays ephemeral; no browser sync.
          ".config/qutebrowser"
          ".local/share/qutebrowser"
        ]
        ++ lib.optionals config.programs.librewolf.enable [
          # Local extension state/bookmarks, not Sync. LibreWolf's own
          # clear-on-close policy still controls cookies and site storage.
          ".librewolf"
        ];

        files = [
          ".claude.json"
        ];
      };
    })
  ];
}

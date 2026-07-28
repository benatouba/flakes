_: {
  config.my.branches.desktop.hmModules = [
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        # Atuin is a history *store* only — it records, it owns no keys.
        # Up/Down  -> zsh native prefix search (see shell/zsh.nix)
        # Ctrl-R   -> fzf over `atuin search` (see dotfiles/zsh/fzf.zsh)
        flags = [
          "--disable-ctrl-r"
          "--disable-up-arrow"
          "--disable-ai" # otherwise atuin grabs '?'
        ];
        settings = {
          enter_accept = true;
          search_mode = "daemon-fuzzy";
          filter_mode = "host";
          style = "compact";
          inline_height = 14;
          show_preview = false;
          show_help = false;
          show_tabs = false;
          accept_past_line_start = true;

          daemon = {
            enabled = true;
            autostart = true;
          };

          keymap_mode = "auto";
        };
      };
    }
  ];
}

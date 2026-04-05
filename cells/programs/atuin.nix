_: {
  config.my.branches.desktop.hmModules = [
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          search_mode = "daemon-fuzzy";
          search_mode_shell_up_key_binding = "prefix";
          filter_mode_shell_up_key_binding = "session";
          style = "compact";
          inline_height = 14;
          inline_height_shell_up_key_binding = 6;
          show_preview = false;
          show_help = false;
          show_tabs = false;

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

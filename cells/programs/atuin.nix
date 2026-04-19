_: {
  config.my.branches.desktop.hmModules = [
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        flags = [
          "--disable-ctrl-r"
          "--disable-up-arrow"
        ];
        settings = {
          search_mode = "daemon-fuzzy";
          filter_mode = "host";
          search_mode_shell_up_key_binding = "prefix";
          filter_mode_shell_up_key_binding = "host";
          style = "compact";
          inline_height = 14;
          inline_height_shell_up_key_binding = 5;
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

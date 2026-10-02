_: {
  config.my.branches.desktop.hmModules = [
    {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
        settings = {
          manager = {
            show_hidden = true;
          };
        };
      };

      # Directory handler (yazi-only setup); launch backend in
      # cells/desktop/terminal-exec.nix.
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "yazi.desktop";
          # Already in ~/.config/mimeapps.list (Claude CLI installs the desktop file).
          "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
        };
      };
    }
  ];
}

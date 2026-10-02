_: {
  # Launches Terminal=true entries (yazi) outside a terminal; without
  # this backend, "Show in folder" and xdg-open on directories fail.
  config.my.branches.desktop.nixosModules = [
    {
      xdg.terminal-exec = {
        enable = true;
        settings.default = [ "org.wezfurlong.wezterm.desktop" ];
      };
    }
  ];
}

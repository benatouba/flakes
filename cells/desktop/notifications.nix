{ config, lib, ... }:
{
  # Only one process may own org.freedesktop.Notifications; the Omarchy shell
  # takes it over when enabled. See cells/desktop/omarchy-shell.nix.
  config.my.branches.desktop.hmModules = lib.optionals (!config.my.enableOmarchyShell) [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ swaynotificationcenter ];

        xdg.configFile."swaync" = {
          source = ../../dotfiles/swaync;
          recursive = true;
        };
      }
    )
  ];
}

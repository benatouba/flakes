{ config, lib, ... }:
{
  # Waybar and the Omarchy Quickshell bar are mutually exclusive: both anchor a
  # layer-shell surface at the top of every monitor. See
  # cells/desktop/omarchy-shell.nix.
  config.my.branches.desktop.nixosModules = lib.optionals (!config.my.enableOmarchyShell) [
    (
      { pkgs, ... }:
      {
        # Plain nixpkgs waybar on purpose.  An overrideAttrs here (previously
        # -Dexperimental=true) changes the derivation hash, so no binary cache
        # can ever serve it and every nixpkgs bump means a full C++ rebuild.
        # The config uses no group/drawer constructs, so nothing needed it.
        environment.systemPackages = with pkgs; [
          waybar
        ];
      }
    )
  ];

  config.my.branches.desktop.hmModules = lib.optionals (!config.my.enableOmarchyShell) [
    {
      xdg.configFile."waybar" = {
        source = ./waybar;
        recursive = true;
      };
    }
  ];
}

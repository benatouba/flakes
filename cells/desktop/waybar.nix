_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        # Plain nixpkgs waybar: an override would lose the binary cache.
        # Already built with -Dexperimental=true, so the stats group works.
        #
        # Clicks broken till nixpkgs ships Waybar PR #5013 (> 0.15.0); scroll works.
        environment.systemPackages = with pkgs; [
          waybar
        ];
      }
    )
  ];

  config.my.branches.desktop.hmModules = [
    {
      xdg.configFile."waybar" = {
        source = ./waybar;
        recursive = true;
      };
    }
  ];
}

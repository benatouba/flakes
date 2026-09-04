_: {
  config.my.branches.desktop.nixosModules = [
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

  config.my.branches.desktop.hmModules = [
    {
      xdg.configFile."waybar" = {
        source = ./waybar;
        recursive = true;
      };
    }
  ];
}

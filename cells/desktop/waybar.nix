{ config, ... }:
{
  config.my.nixosModules = [({ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      waybar
    ];

    nixpkgs.overlays = [
      (_final: prev: {
        waybar = prev.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      })
    ];
  })];

  config.my.hmModules = [{
    xdg.configFile."waybar" = {
      source = ./waybar;
      recursive = true;
    };
  }];
}

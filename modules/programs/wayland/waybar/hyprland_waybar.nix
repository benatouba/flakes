{ config, lib, pkgs, user, ... }:

{
  environment.systemPackages = with pkgs; [
    waybar
  ];

  nixpkgs.overlays = [
    (final: prev: {
      waybar = prev.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      });
    })
  ];

  home-manager.users.${user} = {
    xdg.configFile."waybar/modules.json".source = ./config/modules.json;
    xdg.configFile."waybar/waybar-quicklinks.json".source = ./config/waybar-quicklinks.json;
    xdg.configFile."waybar/themes".source = ./config/themes;
  };
}

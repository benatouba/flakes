{ pkgs, user, ... }:

{
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

  home-manager.users.${user} = {
    xdg.configFile."waybar" = {
      source = ../programs/wayland/waybar/config;
      recursive = true;
    };
  };
}

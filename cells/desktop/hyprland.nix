{ config, inputs, lib, ... }:
let
  theme = config.my.theme;
  themeConf = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (name: hex:
      "$" + name + " = rgb(" + hex + ")\n" +
      "$" + name + "Alpha = " + hex
    ) theme.colors);
in
{
  # NixOS side
  config.my.nixosModules = [({ pkgs, ... }: {
    programs.hyprland.enable = true;

    environment.systemPackages = with pkgs; [
      inputs.hyprpicker.packages.${pkgs.stdenv.hostPlatform.system}.hyprpicker
      hyprlock
      pamixer
    ];

    security.pam.services.hyprlock = { };
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      configPackages = [ pkgs.hyprland ];
      config = {
        hyprland = {
          default = [ "hyprland" "gtk" ];
        };
        common = {
          default = [ "*" ];
        };
      };
    };

    security.polkit.enable = true;
    programs.dconf.enable = true;
  })];

  # HM side
  config.my.hmModules = [{
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      extraConfig = builtins.concatStringsSep "\n" ([
        themeConf
      ] ++ (map builtins.readFile [
        ./hyprland/monitors.conf
        ./hyprland/input.conf
        ./hyprland/appearance.conf
        ./hyprland/keybinds.conf
        ./hyprland/workspaces.conf
        ./hyprland/autostart.conf
        ./hyprland/rules.conf
      ]));
    };

    xdg.configFile."hypr/hypridle.conf".source = ./hyprland/hypridle.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ./hyprland/hyprpaper.conf;
    xdg.configFile."hypr/hyprlock.conf".source = ./hyprland/hyprlock.conf;
    xdg.configFile."hypr/hyprlock/status.sh" = {
      source = ./hyprland/hyprlock/status.sh;
      executable = true;
    };
    xdg.configFile."hypr/scripts/refresh.sh" = {
      source = ./hyprland/scripts/refresh.sh;
      executable = true;
    };
    xdg.configFile."hypr/scripts/random-wallpaper.sh" = {
      source = ./hyprland/scripts/random-wallpaper.sh;
      executable = true;
    };
    xdg.configFile."hypr/scripts/toggle-charge.sh" = {
      source = ./hyprland/scripts/toggle-charge.sh;
      executable = true;
    };
    xdg.configFile."hypr/scripts/power.sh" = {
      source = ./hyprland/scripts/power.sh;
      executable = true;
    };
    xdg.configFile."hypr/assets/blank.png".source = ./hyprland/assets/blank.png;

    # Waypaper
    xdg.configFile."waypaper/config.ini".source = ./waypaper/config.ini;

    # Sidepad
    xdg.configFile."sidepad/sidepad" = {
      source = ./sidepad/sidepad;
      executable = true;
    };
    xdg.configFile."sidepad/pads/wezterm".source = ./sidepad/pads/wezterm;
  }];
}

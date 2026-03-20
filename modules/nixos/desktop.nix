{ pkgs, inputs, ... }:

{
  imports = [ ./waybar.nix ];

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

  services = {
    dbus.packages = [ pkgs.gcr ];
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --kb-layout 'de,us' --kb-option 'grp:alt_shift_toggle' --cmd start-hyprland";
          user = "greeter";
        };
      };
    };
    gvfs.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  security.polkit.enable = true;
  programs.dconf.enable = true;
}

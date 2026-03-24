{ config, ... }:
let
  user = config.my.user.name;
in
{
  config.my.nixosModules = [({ pkgs, ... }: {
    users.users.root.hashedPasswordFile = "/persist/passwords/root";
    users.users.${user} = {
      hashedPasswordFile = "/persist/passwords/${user}";
      shell = pkgs.zsh;
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
      packages = with pkgs; [ gdal hugo gimp nodejs pnpm ];
    };

    environment = {
      systemPackages = with pkgs; [
        libnotify
        wl-clipboard
        wireplumber
        nemo
        networkmanagerapplet
        wev
        wf-recorder
        alsa-lib
        alsa-utils
        flac
        pulsemixer
        imagemagick
        pkgs.sway-contrib.grimshot
        grim
        brightnessctl
        playerctl
        cliphist
        rofi-rbw
        hyprshot
        hyprpaper
        hypridle
        wlsunset
        waypaper
        jq
        wlogout
      ];
    };
  })];
}

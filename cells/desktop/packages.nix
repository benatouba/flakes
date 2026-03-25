{ ... }:
{
  config.my.nixosModules = [({ pkgs, ... }: {
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs; [
      brightnessctl
      cliphist
      grim
      pkgs.sway-contrib.grimshot
      hyprpaper
      hypridle
      hyprshot
      imagemagick
      jq
      libnotify
      nemo
      networkmanagerapplet
      playerctl
      rofi-rbw
      waypaper
      wev
      wf-recorder
      wl-clipboard
      wlogout
      wlsunset
    ];
  })];
}

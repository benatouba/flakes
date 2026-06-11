_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        programs.kdeconnect.enable = true;

        networking.firewall = {
          allowedTCPPortRanges = [
            {
              from = 1714;
              to = 1764;
            }
          ];
          allowedUDPPortRanges = [
            {
              from = 1714;
              to = 1764;
            }
          ];
        };

        services.gvfs.enable = true;

        environment.systemPackages = with pkgs; [
          brightnessctl
          cliphist
          grim
          pkgs.sway-contrib.grimshot
          hyprpaper
          hypridle
          hyprshot
          hyprsunset
          imagemagick
          jq
          libnotify
          kdePackages.kdeconnect-kde
          nemo
          networkmanagerapplet
          playerctl
          rofi-rbw
          waypaper
          wev
          wf-recorder
          wl-clipboard
          wlogout
        ];
      }
    )
  ];
}

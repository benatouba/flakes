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
          # Terminal for waybar popups (bluetooth/audio); see waybar theme config.
          #
          # No wifi picker: impala needs iwd, but NetworkManager uses wpa_supplicant.
          bluetui
          wiremix
          cliphist
          grim
          pkgs.sway-contrib.grimshot
          hyprpaper
          hypridle
          hyprsunset
          imagemagick
          jq
          # Picker for capture.nix (drives grim/slurp directly).
          slurp
          satty
          libnotify
          kdePackages.kdeconnect-kde
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

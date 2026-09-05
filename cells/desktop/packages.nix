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
          # Terminal front-ends the waybar modules open, for the parts a GTK
          # popup menu cannot do: enumerating bluetooth devices and
          # per-application audio streams. See
          # cells/desktop/waybar/themes/catppuccin/config.
          #
          # Wi-Fi has no entry here on purpose: impala would be the obvious
          # pick, but it drives iwd, and networking.nix pins NetworkManager to
          # wpa_supplicant. nmtui comes with NetworkManager and works as-is.
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
          # Region selection and annotation for cells/scripts/capture.nix.
          # hyprshot used to vendor its own picker; the capture commands drive
          # grim and slurp directly, so the picker has to be installed.
          slurp
          satty
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

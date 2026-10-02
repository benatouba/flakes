_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ swaynotificationcenter ];

        xdg.configFile."swaync" = {
          source = ../../dotfiles/swaync;
          recursive = true;
        };

        # Not HM services.swaync: it always writes config.json, colliding with dotfiles.
        # Custom unit instead; it also restarts swaync (refresh.sh pkill was flaky).
        systemd.user.services.swaync = {
          Unit = {
            Description = "Notification daemon";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            # No Wayland display means restart-loop (from the packaged unit).
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
            # Reload both config and CSS, matching the upstream unit.
            ExecReload = "${pkgs.swaynotificationcenter}/bin/swaync-client --reload-config ; ${pkgs.swaynotificationcenter}/bin/swaync-client --reload-css";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      }
    )
  ];
}

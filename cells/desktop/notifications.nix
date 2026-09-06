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

        # Deliberately not home-manager's `services.swaync`. That module writes
        # `swaync/config.json` from its own `settings` option unconditionally —
        # not gated on settings being non-empty the way the hypr* modules are —
        # so enabling it would collide with the recursive dotfiles copy above
        # and fail activation. Adopting it properly would mean porting the whole
        # of dotfiles/swaync/config.json into Nix, which is a separate decision.
        #
        # The unit itself is the part worth having: swaync used to be a bare
        # exec-once with nothing to restart it, and refresh.sh's attempt to
        # restart it is commented out precisely because the pkill-and-sleep
        # dance was unreliable.
        systemd.user.services.swaync = {
          Unit = {
            Description = "Notification daemon";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            # Also from the packaged unit: without a Wayland display there is
            # nothing to draw on, and the service would restart-loop.
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
            # Both halves, matching the unit the package itself ships: a config
            # reload alone leaves the stylesheet stale.
            ExecReload = "${pkgs.swaynotificationcenter}/bin/swaync-client --reload-config ; ${pkgs.swaynotificationcenter}/bin/swaync-client --reload-css";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      }
    )
  ];
}

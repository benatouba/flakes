_: {
  # Thinkpad-only wiring for the project-hours tool (see flakes issue
  # "project-hours NixOS wiring" and the tool repo's
  # docs/spec/01-project-hours-build.md). config.my.hosts.thinkpad.hmModules,
  # NOT config.my.branches.desktop.hmModules: this is single-host, not shared.
  config.my.hosts.thinkpad.hmModules = [
    (
      { pkgs, inputs, ... }:
      let
        projectHours = inputs.project-hours.packages.${pkgs.stdenv.hostPlatform.system}.project-hours;
      in
      {
        services.activitywatch = {
          enable = true;
          package = pkgs.aw-server-rust;

          # awatcher (2e3s/awatcher) always tracks both idle and the active
          # window in one binary -- there is no CLI flag to disable window
          # tracking, unlike classic aw-watcher-afk/aw-watcher-window as two
          # programs. The locked v1 decision is AFK-only, no window watcher
          # (docs/spec/01-project-hours-build.md), so the catch-all filter
          # below (xdg.configFile) drops every window app-id/title before it
          # is ever sent to the server -- idle/AFK reporting is a separate
          # code path in awatcher and is unaffected by it. Thresholds go via
          # extraOptions rather than the generic watchers.*.settings file:
          # that option writes to
          # $XDG_CONFIG_HOME/activitywatch/awatcher/awatcher.toml, but
          # awatcher itself only ever reads $XDG_CONFIG_HOME/awatcher/config.toml
          # (see its README), so settings would silently do nothing here.
          watchers.awatcher = {
            package = pkgs.awatcher;
            extraOptions = [
              "--idle-timeout"
              "600" # matches project-hours' IDLE_CUTOFF_S
              "--poll-time-idle"
              "2"
            ];
          };
        };

        # See the settings/extraOptions split explained above: this is
        # awatcher's real config path, hand-written because the generic
        # services.activitywatch.watchers.*.settings mechanism targets the
        # wrong directory for this particular watcher.
        xdg.configFile."awatcher/config.toml".text = ''
          [[awatcher.filters]]
          match-app-id = ".*"
        '';

        systemd.user.services.wezterm-cwd-watcher = {
          Unit = {
            Description = "wezterm focused-pane cwd -> ActivityWatch heartbeat";
            PartOf = [ "graphical-session.target" ];
            # Depend on ActivityWatch being up first so a cold boot doesn't
            # crash-loop before aw-server-rust has a chance to start
            # (ensure_bucket() in the watcher isn't itself retried).
            After = [
              "graphical-session.target"
              "activitywatch.target"
            ];
          };
          Service = {
            ExecStart = "${projectHours}/bin/wezterm-cwd-watcher";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        # The watcher unit above pins the project-hours store path, so every
        # rebuild regenerates the unit — but Home Manager only restarts a
        # changed user service in sdswitch mode. Without this, a rebuild
        # relinks the unit while the stale watcher keeps running (observed
        # 2026-09-24: unit relinked 21:47, process still the 00:47 build).
        systemd.user.startServices = "sd-switch";

        home.packages = [ projectHours ];

        # Thinkpad-only: NOT added to the shared cells/persist/home.nix
        # (persist branch), since no other host runs this tool.
        home.persistence."/persist".directories = [
          ".local/share/activitywatch"
          ".local/share/project-hours"
        ];
      }
    )
  ];
}

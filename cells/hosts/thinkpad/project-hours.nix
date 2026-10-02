_: {
  # Thinkpad-only project-hours wiring (flakes issue "project-hours NixOS wiring",
  # tool docs/spec/01-project-hours-build.md); not shared desktop branch.
  config.my.hosts.thinkpad.hmModules = [
    (
      {
        pkgs,
        inputs,
        lib,
        ...
      }:
      let
        projectHours = inputs.project-hours.packages.${pkgs.stdenv.hostPlatform.system}.project-hours;
      in
      {
        # Completions live in share/zsh/site-functions; mkBefore puts them on fpath
        # before compinit in cells/shell/zsh.nix. Thinkpad-only.
        programs.zsh.initContent = lib.mkBefore ''
          fpath=(~/.nix-profile/share/zsh/site-functions $fpath)
        '';

        services.activitywatch = {
          enable = true;
          package = pkgs.aw-server-rust;

          # AFK-only: awatcher has no no-window flag, so catch-all filter drops window data.
          # Thresholds via extraOptions; watchers.*.settings writes a path awatcher never reads.
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

        # Real awatcher config path; generic watchers.*.settings targets the wrong dir.
        xdg.configFile."awatcher/config.toml".text = ''
          [[awatcher.filters]]
          match-app-id = ".*"
        '';

        systemd.user.services.wezterm-cwd-watcher = {
          Unit = {
            Description = "wezterm focused-pane cwd -> ActivityWatch heartbeat";
            PartOf = [ "graphical-session.target" ];
            # Start after ActivityWatch so cold boot doesn't crash-loop
            # (ensure_bucket() isn't retried).
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

        # Unit pins store path; without sd-switch a rebuild relinks while stale watcher runs
        # (observed 2026-09-24). Requires sd-switch restart mode.
        systemd.user.startServices = "sd-switch";

        home.packages = [ projectHours ];

        # Thinkpad-only persist; no other host runs this tool.
        home.persistence."/persist".directories = [
          ".local/share/activitywatch"
          ".local/share/project-hours"
        ];
      }
    )
  ];
}

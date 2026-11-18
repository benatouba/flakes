# Eval-time check of the thinkpad project-hours watcher wiring: the
# terminal-independent watcher replaces the WezTerm one (two watchers must
# never feed the same bucket, project-hours ADR-0005).
{
  config,
  lib,
  ...
}:
let
  nixos = config.flake.nixosConfigurations.thinkpad.config;
  hm = nixos.home-manager.users.${config.my.user.name};

  failing = cases: lib.attrNames (lib.filterAttrs (_: ok: !ok) cases);

  userServices = hm.systemd.user.services;
  watcher = userServices.terminal-cwd-watcher or { };
  projectHours = lib.findFirst (p: lib.getName p == "project-hours") null hm.home.packages;
  # The wrapper's PATH prefix: the watcher shells out to git and ps.
  wrapperPath = toString (projectHours.makeWrapperArgs or [ ]);

  cases = {
    "thinkpad-runs-terminal-cwd-watcher" =
      lib.any (lib.hasSuffix "/bin/terminal-cwd-watcher") (lib.toList (watcher.Service.ExecStart or [ ]))
      && lib.elem "activitywatch.target" (watcher.Unit.After or [ ]);
    "thinkpad-no-wezterm-cwd-watcher" = !(userServices ? wezterm-cwd-watcher);
    "watcher-path-has-git" = lib.hasInfix "-git-" wrapperPath;
    "watcher-path-has-ps" = lib.hasInfix "-procps-" wrapperPath;
    # The watcher reads Hyprland's IPC socket; the graphical session must
    # export the instance signature to the systemd user manager.
    "watcher-gets-hyprland-instance" =
      hm.wayland.windowManager.hyprland.systemd.enable
      && lib.elem "HYPRLAND_INSTANCE_SIGNATURE" hm.wayland.windowManager.hyprland.systemd.variables;
  };
  failed = failing cases;
in
{
  config.perSystem =
    { pkgs, ... }:
    {
      checks.thinkpad-watcher = pkgs.runCommand "thinkpad-watcher-check" { } (
        if failed == [ ] then
          "touch $out"
        else
          "echo ${lib.escapeShellArg "failed: ${lib.concatStringsSep ", " failed}"}; exit 1"
      );
    };
}

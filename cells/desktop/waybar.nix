_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        # Plain nixpkgs waybar on purpose. An overrideAttrs here changes the
        # derivation hash, so no binary cache could serve it and every nixpkgs
        # bump would mean a full C++ rebuild.
        #
        # The config *does* use a group module now (the cpu/memory/disk stats
        # group) and still needs no override: nixpkgs builds waybar with
        # `experimentalPatches ? true`, so -Dexperimental=true is already on in
        # the cached build. An earlier version of this comment said otherwise.
        #
        # Known broken while this stays unpatched: clicking a workspace button
        # does not switch workspace. hyprland/workspaces hardcodes the legacy
        # `dispatch workspace name:<x>` string in C++, and hyprland >= 0.55 runs
        # a lua config where the IPC `dispatch` verb evaluates lua, so it comes
        # back as a lua syntax error and nothing happens. Upstream fixed it in
        # Waybar PR #5013 (merged 2026-05-04, auto-detects the protocol, needs
        # no config change), but nixpkgs still ships 0.15.0, which predates it.
        # Deliberately waiting for that release rather than carrying a patch, to
        # keep the cached build above. Scrolling the same module *is* fixed, in
        # the theme config, because that one goes through a shell command.
        environment.systemPackages = with pkgs; [
          waybar
        ];
      }
    )
  ];

  config.my.branches.desktop.hmModules = [
    {
      xdg.configFile."waybar" = {
        source = ./waybar;
        recursive = true;
      };
    }
  ];
}

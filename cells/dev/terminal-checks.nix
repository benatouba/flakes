# Eval-time check that Ghostty (with shpool sessions) is the default desktop
# terminal on thinkpad and WezTerm is only a fallback. Each case names one
# place WezTerm used to be the default, so a regression is legible.
{
  config,
  lib,
  ...
}:
let
  nixos = config.flake.nixosConfigurations.thinkpad.config;
  hm = nixos.home-manager.users.${config.my.user.name};

  failing = cases: lib.attrNames (lib.filterAttrs (_: ok: !ok) cases);
  mentionsWezterm = lib.hasInfix "wezterm";
  linesOf = text: map lib.trim (lib.splitString "\n" text);

  # Active (Lua) Hyprland config and the hyprlang fallback sources.
  hyprland = hm.wayland.windowManager.hyprland.extraConfig;
  legacy = name: builtins.readFile (../desktop/hyprland + "/${name}");
  legacyAll = lib.concatMapStringsSep "\n" legacy [
    "keybinds.conf"
    "workspaces.conf"
    "autostart.conf"
    "appearance.conf"
  ];

  # Lines that pick the terminal: the terminal variable, workspace rules and
  # the Lua on_created_empty table entries (`["name:x"] = "cmd",`).
  launchesTerminal =
    line:
    lib.hasPrefix "local terminal" line
    || lib.hasPrefix "$terminal" line
    || lib.hasPrefix "workspace =" line
    || builtins.match "\\[\".*\"] = \".*\",?" line != null;
  weztermLaunchers = text: lib.filter (l: launchesTerminal l && mentionsWezterm l) (linesOf text);
  swallowsGhostty =
    text: lib.any (l: lib.hasInfix "swallow_regex" l && lib.hasInfix "ghostty" l) (linesOf text);

  waybarConfig =
    theme: builtins.readFile (hm.xdg.configFile.waybar.source + "/themes/${theme}/config");

  cases = {
    "hyprland-terminal-not-wezterm" = weztermLaunchers hyprland == [ ];
    "hyprland-legacy-terminal-not-wezterm" = weztermLaunchers legacyAll == [ ];
    "hyprland-terminal-uses-session-launcher" =
      lib.hasInfix "local terminal = \"ghostty-session\"" hyprland;
    "hyprland-picker-keybind" = lib.hasInfix "CTRL + ALT + SHIFT + t" hyprland;
    "hyprland-legacy-picker-keybind" = lib.hasInfix "CTRL ALT SHIFT, t" legacyAll;
    "no-wezterm-mux-autostart" = !(lib.hasInfix "wezterm-mux-server" hyprland);
    "no-legacy-wezterm-mux-autostart" = !(lib.hasInfix "wezterm-mux-server" legacyAll);
    "hyprland-swallows-ghostty" = swallowsGhostty hyprland;
    "hyprland-legacy-swallows-ghostty" = swallowsGhostty legacyAll;
    "hyprland-tiles-ghostty" = lib.hasInfix "com\\.mitchellh\\.ghostty" (legacy "rules.conf");
    "waybar-catppuccin-not-wezterm" = !(mentionsWezterm (waybarConfig "catppuccin"));
    "waybar-default-not-wezterm" = !(mentionsWezterm (waybarConfig "default"));
    "terminal-exec-defaults-to-ghostty" =
      nixos.xdg.terminal-exec.settings.default == [ "com.mitchellh.ghostty.desktop" ];
    "terminal-variable-is-ghostty" = (hm.home.sessionVariables.TERMINAL or null) == "ghostty";
    "sidepad-uses-ghostty" =
      hm.xdg.configFile ? "sidepad/pads/ghostty" && !(hm.xdg.configFile ? "sidepad/pads/wezterm");
    "ghostty-enabled-with-systemd" = hm.programs.ghostty.enable && hm.programs.ghostty.systemd.enable;
    "ghostty-catppuccin-themed" = hm.catppuccin.ghostty.enable;
    "shpool-enabled" = hm.services.shpool.enable;
    "wezterm-kept-as-fallback" = hm.programs.wezterm.enable;
    "wezterm-does-not-attach-mux" = !(lib.hasInfix "\"connect\"" hm.programs.wezterm.extraConfig);
  };
  failed = failing cases;
in
{
  config.perSystem =
    { pkgs, ... }:
    {
      checks.terminal-default = pkgs.runCommand "terminal-default-check" { } (
        if failed == [ ] then
          "touch $out"
        else
          "echo ${lib.escapeShellArg "failed: ${lib.concatStringsSep ", " failed}"}; exit 1"
      );
    };
}

{
  config,
  inputs,
  lib,
  ...
}:
let
  theme = config.my.theme;

  luaString = builtins.toJSON;
  luaBool = value: if value then "true" else "false";
  luaValue =
    value:
    if builtins.isBool value then
      luaBool value
    else if builtins.isInt value || builtins.isFloat value then
      toString value
    else
      luaString value;
  luaKv = name: value: "  " + name + " = " + luaValue value + ",";
  luaCall = name: args: "hl." + name + "({\n" + lib.concatStringsSep "\n" args + "\n})";

  colorVars = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: hex: ''
      local ${name} = ${luaString "rgb(${hex})"}
      local ${name}Alpha = ${luaString hex}
    '') theme.colors
  );

  themeConf = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: hex: ''
      ${"$"}${name} = rgb(${hex})
      ${"$"}${name}Alpha = ${hex}
    '') theme.colors
  );

  cursorEnvConf = "env = XCURSOR_SIZE, ${toString theme.cursor.size}";

  legacyHyprlandConfig = builtins.concatStringsSep "\n" (
    [
      themeConf
      cursorEnvConf
    ]
    ++ map builtins.readFile [
      ./hyprland/monitors.conf
      ./hyprland/input.conf
      ./hyprland/appearance.conf
      ./hyprland/keybinds.conf
      ./hyprland/workspaces.conf
      ./hyprland/autostart.conf
      ./hyprland/rules.conf
    ]
  );

  trim = lib.trim;
  nonEmptyLines =
    text:
    builtins.filter (line: line != "" && !(lib.hasPrefix "#" line)) (
      map trim (lib.splitString "\n" text)
    );

  parseRuleLine =
    line:
    let
      parsed = builtins.match "([^=]+) = (.*)" line;
    in
    if parsed == null then
      null
    else
      {
        key = trim (builtins.elemAt parsed 0);
        value = trim (builtins.elemAt parsed 1);
      };

  parseRuleBlocks =
    lines:
    let
      go =
        acc: current: remaining:
        if remaining == [ ] then
          lib.reverseList acc
        else
          let
            line = builtins.head remaining;
            rest = builtins.tail remaining;
          in
          if line == "layerrule {" then
            go acc {
              kind = "layer_rule";
              properties = [ ];
            } rest
          else if line == "windowrule {" then
            go acc {
              kind = "window_rule";
              properties = [ ];
            } rest
          else if line == "}" && current != null then
            go ([ current ] ++ acc) null rest
          else if current != null then
            let
              property = parseRuleLine line;
            in
            go acc (
              current // { properties = current.properties ++ lib.optional (property != null) property; }
            ) rest
          else
            go acc current rest;
    in
    go [ ] null lines;

  ruleValue =
    value:
    if value == "true" then
      "true"
    else if value == "false" then
      "false"
    else if builtins.match "-?[0-9]+(\\.[0-9]+)?" value != null then
      value
    else
      luaString value;

  ruleToLua =
    rule:
    let
      matchProperties = builtins.filter (property: lib.hasPrefix "match:" property.key) rule.properties;
      normalProperties = builtins.filter (
        property: !(lib.hasPrefix "match:" property.key)
      ) rule.properties;
      matchLua = lib.optionalString (matchProperties != [ ]) (
        ''
          match = {
        ''
        + lib.concatStringsSep "\n" (
          map (
            property: "    ${lib.removePrefix "match:" property.key} = ${luaString property.value},"
          ) matchProperties
        )
        + ''
          },
        ''
      );
      propertiesLua = lib.concatStringsSep "\n" (
        map (property: "  ${property.key} = ${ruleValue property.value},") normalProperties
      );
    in
    ''
      hl.${rule.kind}({
      ${matchLua}${propertiesLua}
      })
    '';

  rulesLua = lib.concatStringsSep "\n" (
    map ruleToLua (parseRuleBlocks (nonEmptyLines (builtins.readFile ./hyprland/rules.conf)))
  );

  monitorLua = lib.concatStringsSep "\n" (
    map
      (
        monitor:
        luaCall "monitor" [
          (luaKv "output" monitor.output)
          (luaKv "mode" monitor.mode)
          (luaKv "position" monitor.position)
          (luaKv "scale" monitor.scale)
          (lib.optionalString (monitor ? mirror) (luaKv "mirror" monitor.mirror))
        ]
      )
      [
        {
          output = "DP-1";
          mode = "preferred";
          position = "auto-left";
          scale = "1.00";
        }
        {
          output = "eDP-1";
          mode = "preferred";
          position = "auto";
          scale = "1.666667";
        }
        {
          output = "HDMI-A-1";
          mode = "preferred";
          position = "auto-left";
          scale = "1.00";
          mirror = "eDP-1";
        }
        {
          output = "X11-1";
          mode = "1024x768@60.00000";
          position = "0x0";
          scale = "1.00";
        }
        {
          output = "desc:BNQ BenQ GL2580 JCJ07368019";
          mode = "1920x1080";
          position = "auto-right";
          scale = "1";
        }
        {
          output = "desc:Samsung Electric Company S24D330 H4LHC17246";
          mode = "preferred";
          position = "auto-left";
          scale = "1";
        }
        {
          output = "desc:Samsung Electric Company S24D330 0x5A5A5131";
          mode = "preferred";
          position = "auto-left";
          scale = "1";
        }
        {
          output = "desc:Lenovo Group Limited LEN C32q-20 0x01010101";
          mode = "preferred";
          position = "auto-left";
          scale = "1";
        }
        {
          output = "desc:Lenovo Group Limited LEN T24h-20 V308ZR3A";
          mode = "preferred";
          position = "auto-left";
          scale = "1";
        }
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "1";
          mirror = "eDP-1";
        }
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "1";
        }
      ]
  );

  workspaceLua = lib.concatStringsSep "\n" (
    map
      (
        workspace:
        luaCall "workspace_rule" (
          [ (luaKv "workspace" workspace.workspace) ]
          ++ lib.optionals (workspace ? monitor) [ (luaKv "monitor" workspace.monitor) ]
          ++ lib.optionals (workspace ? default) [ (luaKv "default" workspace.default) ]
          ++ lib.optionals (workspace ? persistent) [ (luaKv "persistent" workspace.persistent) ]
          ++ lib.optionals (workspace ? on_created_empty) [
            (luaKv "on_created_empty" workspace.on_created_empty)
          ]
        )
      )
      [
        {
          workspace = "1";
          monitor = "eDP-1";
          persistent = true;
        }
        {
          workspace = "2";
          monitor = "DP-1";
          persistent = true;
        }
        {
          workspace = "name:web";
          monitor = "DP-1";
          default = true;
          persistent = true;
          on_created_empty = "brave";
        }
        {
          workspace = "name:terminal";
          monitor = "DP-1";
          persistent = true;
          on_created_empty = "wezterm connect unix";
        }
        {
          workspace = "name:email";
          monitor = "eDP-1";
          persistent = true;
          on_created_empty = "thunderbird";
        }
        {
          workspace = "name:music";
          monitor = "DP-1";
          persistent = true;
          on_created_empty = "spotify";
        }
        {
          workspace = "name:coding";
          monitor = "DP-1";
          on_created_empty = "wezterm";
        }
        {
          workspace = "special";
          on_created_empty = "wezterm connect unix";
        }
      ]
  );

  autostartLua = lib.concatStringsSep "\n" (
    map
      (command: ''
        hl.exec_cmd(${luaString command})
      '')
      [
        "~/.config/hypr/scripts/resetXdgPortal.sh"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user start hyprpolkitagent"
        "systemctl --user restart pipewire"
        "launch-waybar"
        "nm-applet"
        "swaync"
        "hyprpaper"
        "sleep 1 && bash ~/.config/hypr/scripts/random-wallpaper.sh"
        "xsettingsd"
        "hyprsunset -t 5200"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "wezterm-mux-server --daemonize --cwd ~/"
        "hypridle"
      ]
  );

  hyprlandLua = ''
    ${colorVars}

    ${monitorLua}

    local mainMod = "SUPER"
    local browser = "brave"
    local terminal = "wezterm connect unix"
    local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"

    local function resize_active(x, y)
      return hl.dsp.window.resize({ x = x, y = y, relative = true })
    end

    hl.env("XCURSOR_SIZE", ${luaString (toString theme.cursor.size)})
    hl.env("QT_QPA_PLATFORMTHEME", "kvantum")
    hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

    hl.config({
      general = {
        border_size = 1,
        col = {
          active_border = { colors = { flamingo, rosewater }, angle = 45 },
          inactive_border = "rgba(595959aa)",
          nogroup_border = { colors = { surface0, surface1 }, angle = 45 },
          nogroup_border_active = { colors = { green, yellow }, angle = 45 },
        },
        gaps_in = 2,
        gaps_out = 3,
        layout = "dwindle",
        resize_on_border = true,
      },
      decoration = {
        rounding = 4,
        blur = {
          enabled = true,
          size = 5,
          passes = 1,
        },
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        dim_inactive = false,
      },
      animations = {
        enabled = true,
      },
      group = {
        insert_after_current = true,
        focus_removed_window = true,
        col = {
          border_active = rosewater,
          border_inactive = subtext0,
          border_locked_active = rosewater,
          border_locked_inactive = subtext0,
        },
      },
      dwindle = {
        preserve_split = true,
      },
      master = {
        new_status = "master",
        new_on_top = true,
        new_on_active = "before",
        mfact = 0.8,
      },
      misc = {
        close_special_on_empty = true,
        disable_autoreload = true,
        animate_manual_resizes = false,
        focus_on_activate = true,
        disable_hyprland_logo = true,
        enable_swallow = true,
        swallow_regex = "^(org\\.wezterm).*$",
      },
      input = {
        kb_layout = "de,us",
        kb_options = "caps:swapescape",
        numlock_by_default = true,
        follow_mouse = 2,
        repeat_delay = 200,
        repeat_rate = 40,
        touchpad = {
          natural_scroll = true,
          tap_to_click = true,
          disable_while_typing = true,
        },
        sensitivity = 0,
      },
      xwayland = {
        force_zero_scaling = true,
      },
      binds = {
        workspace_back_and_forth = 1,
        allow_workspace_cycles = 1,
      },
    })

    hl.curve("overshot", { type = "bezier", points = { { 0.13, 0.99 }, { 0.29, 1.1 } } })
    hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "overshot", style = "slide" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "default", style = "popin 80%" })
    hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
    hl.animation({ leaf = "fade", enabled = true, speed = 8, bezier = "default" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "overshot", style = "slidevert" })

    hl.device({
      name = "cherry-usb-keyboard",
      kb_layout = "us",
      kb_options = "caps:swapescape, compose:menu",
    })
    hl.device({
      name = "rapoo-rapoo-5g-wireless-device",
      kb_layout = "de,us",
      kb_options = "caps:swapescape, compose:menu",
    })
    hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

    ${workspaceLua}

    hl.on("hyprland.start", function()
      ${autostartLua}
    end)

    hl.bind(mainMod .. " + d", hl.dsp.exec_cmd("pkill rofi || rofi -show combi"))
    hl.bind("CTRL + ALT + t", hl.dsp.exec_cmd(terminal))
    hl.bind(mainMod .. " + Q", hl.dsp.window.close())
    hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())
    hl.bind(mainMod .. " + Space", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + CTRL + Space", hl.dsp.group.toggle())
    hl.bind(mainMod .. " + n", hl.dsp.group.next())
    hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
    hl.bind(mainMod .. " + Y", hl.dsp.window.pin())
    hl.bind(mainMod .. " + p", hl.dsp.window.pseudo())
    hl.bind(mainMod .. " + t", hl.dsp.layout("togglesplit"))
    hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload && bash " .. scriptsDir .. "/refresh.sh"))

    hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
    hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
    hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
    hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

    hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left", group_aware = true }))
    hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right", group_aware = true }))
    hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up", group_aware = true }))
    hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down", group_aware = true }))
    hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
    hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
    hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
    hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

    for i = 1, 10 do
      local key = i % 10
      hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
      hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
      hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = tostring(i), follow = false }))
    end

    hl.bind(mainMod .. " + w", hl.dsp.focus({ workspace = "name:web" }))
    hl.bind(mainMod .. " + e", hl.dsp.focus({ workspace = "name:email" }))
    hl.bind(mainMod .. " + m", hl.dsp.focus({ workspace = "name:music" }))
    hl.bind(mainMod .. " + Return", hl.dsp.focus({ workspace = "name:terminal" }))
    hl.bind(mainMod .. " + S", hl.dsp.focus({ workspace = "name:stream" }))
    hl.bind(mainMod .. " + Tab", hl.dsp.window.cycle_next())
    hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
    hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mainMod .. " + C", hl.dsp.workspace.toggle_special(""))
    hl.bind(mainMod .. " + minus", hl.dsp.window.move({ workspace = "special" }))
    hl.bind(mainMod .. " + equal", hl.dsp.workspace.toggle_special(""))

    hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }))
    hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }))
    hl.bind(mainMod .. " + SHIFT + w", hl.dsp.window.move({ workspace = "name:web" }))
    hl.bind(mainMod .. " + SHIFT + e", hl.dsp.window.move({ workspace = "name:email" }))
    hl.bind(mainMod .. " + SHIFT + m", hl.dsp.window.move({ workspace = "name:music" }))
    hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.window.move({ workspace = "name:terminal" }))
    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "name:stream" }))
    hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.move({ workspace = "special" }))
    hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ workspace = "-1", follow = false }))
    hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ workspace = "+1", follow = false }))
    hl.bind(mainMod .. " + CTRL + w", hl.dsp.window.move({ workspace = "name:web", follow = false }))
    hl.bind(mainMod .. " + CTRL + e", hl.dsp.window.move({ workspace = "name:email", follow = false }))
    hl.bind(mainMod .. " + CTRL + m", hl.dsp.window.move({ workspace = "name:music", follow = false }))
    hl.bind(mainMod .. " + CTRL + Return", hl.dsp.window.move({ workspace = "name:terminal", follow = false }))
    hl.bind(mainMod .. " + CTRL + S", hl.dsp.window.move({ workspace = "name:stream", follow = false }))

    hl.bind("ALT + SHIFT + 1", hl.dsp.workspace.move({ monitor = "0" }))
    hl.bind("ALT + SHIFT + 2", hl.dsp.workspace.move({ monitor = "1" }))
    hl.bind("ALT + SHIFT + 3", hl.dsp.workspace.move({ monitor = "2" }))
    hl.bind("ALT + SHIFT + m", hl.dsp.workspace.move({ monitor = "+1" }))

    hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
    hl.define_submap("resize", function()
      hl.bind("right", resize_active(15, 0), { repeating = true })
      hl.bind("left", resize_active(-15, 0), { repeating = true })
      hl.bind("up", resize_active(0, -15), { repeating = true })
      hl.bind("down", resize_active(0, 15), { repeating = true })
      hl.bind("l", resize_active(15, 0), { repeating = true })
      hl.bind("h", resize_active(-15, 0), { repeating = true })
      hl.bind("k", resize_active(0, -15), { repeating = true })
      hl.bind("j", resize_active(0, 15), { repeating = true })
      hl.bind("escape", hl.dsp.submap("reset"))
      hl.bind(mainMod .. " + R", hl.dsp.submap("reset"))
    end)
    hl.bind("CTRL + SHIFT + left", resize_active(-15, 0))
    hl.bind("CTRL + SHIFT + right", resize_active(15, 0))
    hl.bind("CTRL + SHIFT + up", resize_active(0, -15))
    hl.bind("CTRL + SHIFT + down", resize_active(0, 15))

    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer --allow-boost -i 5"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t && amixer -q -c1 sset Capture toggle"), { locked = true })
    hl.bind(mainMod .. " + F4", hl.dsp.exec_cmd("pamixer --default-source -t && amixer -q -c1 sset Capture toggle"))
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -c backlight set +5%"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -c backlight set 5%-"), { locked = true, repeating = true })
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
    hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region"))
    hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -zm region"))
    hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m display"))
    hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("hyprctl --batch \"keyword general:gaps_out 5;keyword general:gaps_in 3\""))
    hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("hyprctl --batch \"keyword general:gaps_out 0;keyword general:gaps_in 0\""))
    hl.bind(mainMod .. " + backslash", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))
    hl.bind("ALT + W", hl.dsp.exec_cmd("bash " .. scriptsDir .. "/random-wallpaper.sh"))
    hl.bind("ALT + SHIFT + C", hl.dsp.exec_cmd("bash " .. scriptsDir .. "/toggle-charge.sh"))
    hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("hyprlock"))
    hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("waybar-toggle"))
    hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -theme cliphist_theme.rasi | cliphist decode | wl-copy"))
    hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("rofi-rbw -a copy -t password --clear-after 20"))
    hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("rofi-rbw --no-help --clear-after 20 --selector-args=\"-theme-str 'window { width: 800px;}'\""))

    ${rulesLua}
  '';
in
{
  # NixOS side
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        programs.hyprland.enable = true;

        environment.systemPackages = with pkgs; [
          inputs.hyprpicker.packages.${pkgs.stdenv.hostPlatform.system}.hyprpicker
          hyprlock
          pamixer
        ];

        security.pam.services.hyprlock = { };
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          configPackages = [ pkgs.hyprland ];
          config = {
            hyprland = {
              default = [
                "hyprland"
                "gtk"
              ];
            };
            common = {
              default = [ "*" ];
            };
          };
        };

        security.polkit.enable = true;
        programs.dconf.enable = true;
      }
    )
  ];

  # HM side
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      let
        useLuaConfig = lib.versionAtLeast (lib.getVersion pkgs.hyprland) "0.55.0";
      in
      {
        warnings =
          lib.optional (!useLuaConfig)
            "Hyprland ${lib.getVersion pkgs.hyprland} does not support Lua config yet; using hyprlang config for parity.";

        wayland.windowManager.hyprland = {
          enable = true;
          package = null;
          portalPackage = null;
          configType = if useLuaConfig then "lua" else "hyprlang";
          plugins = [
            # TODO: re-enable when hyprexpo is compatible with Hyprland 0.54.0
            # inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
          ];
          extraConfig = if useLuaConfig then hyprlandLua else legacyHyprlandConfig;
        };

        xdg.configFile."hypr/hypridle.conf".source = ./hyprland/hypridle.conf;
        xdg.configFile."hypr/hyprpaper.conf".source = ./hyprland/hyprpaper.conf;
        xdg.configFile."hypr/hyprlock.conf".source = ./hyprland/hyprlock.conf;
        xdg.configFile."hypr/hyprlock/status.sh" = {
          source = ./hyprland/hyprlock/status.sh;
          executable = true;
        };
        xdg.configFile."hypr/scripts/refresh.sh" = {
          source = ./hyprland/scripts/refresh.sh;
          executable = true;
        };
        xdg.configFile."hypr/scripts/random-wallpaper.sh" = {
          source = ./hyprland/scripts/random-wallpaper.sh;
          executable = true;
        };
        xdg.configFile."hypr/scripts/toggle-charge.sh" = {
          source = ./hyprland/scripts/toggle-charge.sh;
          executable = true;
        };
        xdg.configFile."hypr/scripts/power.sh" = {
          source = ./hyprland/scripts/power.sh;
          executable = true;
        };
        xdg.configFile."hypr/assets/blank.png".source = ./hyprland/assets/blank.png;

        # Waypaper
        xdg.configFile."waypaper/config.ini".source = ./waypaper/config.ini;

        # Sidepad
        xdg.configFile."sidepad/sidepad" = {
          source = ./sidepad/sidepad;
          executable = true;
        };
        xdg.configFile."sidepad/pads/wezterm".source = ./sidepad/pads/wezterm;
      }
    )
  ];
}

# A partial vendoring of the Omarchy 4 ("Quattro") Quickshell desktop shell.
#
# Upstream ships one long-running Quickshell process hosting bar, menu,
# launcher, lock screen, notifications, OSD and a dozen panels as plugins, glued
# together by ~440 `omarchy-*` scripts. We take only the slice that has no Arch
# coupling — bar, OSD, notifications and the panels that back the bar's right
# section — and leave rofi, hyprlock, hypridle and wlogout in place.
#
# `shellPaths` and `scripts` below are deliberately explicit allowlists rather
# than exclusion lists: bumping the `omarchy` flake input must never pull in a
# new plugin (and its unreviewed helper scripts) silently. When bumping, re-run
# the closure check documented in cells/desktop/omarchy-shell.nix.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  omarchySrc,

  # The shell hardcodes the fontconfig alias "monospace" for every label and
  # icon it draws (shell/Commons/Style.qml: "the family stays system-wide"),
  # and upstream retargets it with `omarchy font set`, which rewrites
  # ~/.config/fontconfig/fonts.conf imperatively. This host aliases monospace
  # to a CJK face with no Nerd Font glyphs, which leaves the bar drawing Latin
  # text in a CJK font and its icons through a fallback with different metrics.
  # Patching the default here retargets the shell alone and leaves the system
  # monospace alias untouched.
  fontFamily ? "monospace",

  bash,
  bluez,
  brightnessctl,
  coreutils,
  ddcutil,
  fontconfig,
  gawk,
  gnugrep,
  gnused,
  hyprland,
  inotify-tools,
  iw,
  jq,
  libnotify,
  libxkbcommon,
  networkmanager,
  pulseaudio,
  quickshell,
  systemd,
  tzdata,
  upower,
  util-linux,
  wireplumber,
  wl-clipboard,
  wtype,
}:
let
  # QML we build the shell from. Everything under shell/plugins that is not
  # listed here is dropped, and PluginRegistry simply never discovers it.
  shellPaths = [
    "shell.qml"
    "Commons"
    "Ui"
    "services"
    "plugins/bar"
    "plugins/osd"
    "plugins/notifications"
    "plugins/clipboard"
    "plugins/emojis"
    "plugins/polkit"
    # The bar's right-section widgets live under plugins/panels: the widget and
    # its popup panel are one plugin, so these are not optional extras.
    "plugins/panels/audio"
    "plugins/panels/bluetooth"
    "plugins/panels/clock"
    "plugins/panels/monitor"
    "plugins/panels/network"
    "plugins/panels/power"
    "plugins/services/battery"
    "plugins/services/media"
    "plugins/services/nightlight"
  ];

  # Transitive closure of the `omarchy-*` scripts the QML above shells out to,
  # minus the roots that reach into pacman/AUR (omarchy-menu, omarchy-update,
  # omarchy-bar) and the ones behind widgets we do not enable (voxtype,
  # reminders, screen recording). Verified free of pacman/snapper/limine.
  scripts = [
    "omarchy-audio-input-mute"
    "omarchy-audio-input-set-default"
    "omarchy-audio-output-set-default"
    "omarchy-audio-output-sink"
    "omarchy-audio-output-volume"
    "omarchy-audio-sink-availability"
    "omarchy-audio-tuning"
    "omarchy-bar-text-color"
    "omarchy-battery-low"
    "omarchy-battery-status"
    "omarchy-bluetooth-device"
    "omarchy-bluetooth-power"
    "omarchy-brightness-display"
    "omarchy-brightness-display-apple"
    "omarchy-brightness-display-ddc"
    "omarchy-brightness-keyboard"
    "omarchy-brightness-keyboard-mute"
    "omarchy-clipboard-open"
    "omarchy-clipboard-paste-file"
    "omarchy-clipboard-paste-text"
    "omarchy-cmd-present"
    "omarchy-display-text-size"
    "omarchy-dns"
    "omarchy-font-set"
    "omarchy-hook"
    "omarchy-hw-clamshell"
    "omarchy-hw-display"
    "omarchy-hw-external-monitors"
    "omarchy-hw-laptop-closed"
    "omarchy-hw-match"
    "omarchy-hyprland-focus-app"
    "omarchy-hyprland-monitor-clamshell"
    "omarchy-hyprland-monitor-external-active"
    "omarchy-hyprland-monitor-focused"
    "omarchy-hyprland-monitor-focused-apple"
    "omarchy-hyprland-monitor-internal"
    "omarchy-hyprland-monitor-internal-mirror"
    "omarchy-hyprland-monitor-laptop"
    "omarchy-hyprland-monitor-scaling"
    "omarchy-hyprland-session-locked"
    # Pure hyprctl + jq, unlike its single-square-aspect sibling, which needs
    # Omarchy's Hyprland toggles layer and is therefore not shipped.
    "omarchy-hyprland-window-transparency-toggle"
    "omarchy-launch-shell"
    "omarchy-menu-select"
    "omarchy-menu-emoji-insert"
    "omarchy-menu-timezone"
    "omarchy-monitor-state"
    "omarchy-network-band"
    "omarchy-network-status"
    "omarchy-notification-dismiss"
    "omarchy-notification-send"
    "omarchy-osd"
    "omarchy-powerprofiles-list"
    "omarchy-powerprofiles-set"
    "omarchy-restart-audio"
    "omarchy-restart-shell"
    "omarchy-shell"
    "omarchy-system-sleep-lock"
    "omarchy-system-stats"
    "omarchy-toggle"
    "omarchy-toggle-bar"
    "omarchy-toggle-nightlight"
  ];

  # The shell reads this as its fallback layout when ~/.config/omarchy/shell.json
  # is missing (e.g. before the first home-manager activation). Ids in it that
  # belong to plugins we do not ship are simply skipped by the registry.
  configPaths = [ "omarchy/shell.json" ];

  # power-profiles-daemon is deliberately absent: this host manages power with
  # TLP (cells/core/power.nix), so the panel's profile switcher has nothing to
  # talk to. `powerprofilesctl list` is already guarded by 2>/dev/null upstream,
  # so the section renders empty instead of erroring.
  runtimeInputs = [
    bash
    bluez
    brightnessctl
    coreutils
    ddcutil
    fontconfig
    gawk
    gnugrep
    gnused
    hyprland
    inotify-tools
    iw
    jq
    libnotify
    libxkbcommon
    networkmanager
    pulseaudio
    quickshell
    systemd
    upower
    util-linux
    wireplumber
    wl-clipboard
    wtype
  ];
in
stdenvNoCC.mkDerivation {
  pname = "omarchy-shell";
  version = "4.0.0-unstable-2026-08-27";

  src = omarchySrc;

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  postPatch = ''
    substituteInPlace bin/omarchy-toggle-nightlight \
      --replace-fail 'setsid uwsm-app -- hyprsunset &' 'setsid hyprsunset &'
  ''
  + lib.optionalString (fontFamily != "monospace") ''
    substituteInPlace shell/Commons/Style.qml \
      --replace-fail 'property string fontFamily: "monospace"' \
                     'property string fontFamily: "${fontFamily}"' \
      --replace-fail 'property string resolvedFontFamily: "monospace"' \
                     'property string resolvedFontFamily: "${fontFamily}"' \
      --replace-fail '"fc-match", "-f", "%{family[0]}", "monospace"' \
                     '"fc-match", "-f", "%{family[0]}", "${fontFamily}"'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/omarchy/shell" "$out/bin"

    for path in ${lib.escapeShellArgs shellPaths}; do
      if [ ! -e "shell/$path" ]; then
        echo "omarchy-shell: allowlisted path shell/$path is gone upstream" >&2
        exit 1
      fi
      mkdir -p "$out/share/omarchy/shell/$(dirname "$path")"
      cp -r "shell/$path" "$out/share/omarchy/shell/$path"
    done

    for path in ${lib.escapeShellArgs configPaths}; do
      if [ ! -e "config/$path" ]; then
        echo "omarchy-shell: allowlisted path config/$path is gone upstream" >&2
        exit 1
      fi
      install -Dm644 "config/$path" "$out/share/omarchy/config/$path"
    done

    for script in ${lib.escapeShellArgs scripts}; do
      if [ ! -e "bin/$script" ]; then
        echo "omarchy-shell: allowlisted script $script is gone upstream" >&2
        exit 1
      fi
      install -Dm755 "bin/$script" "$out/bin/$script"
    done

    # The vendored tree carries its own scripts — services/hidden-entries.sh
    # (invoked from AppLibrary.qml) and plugins/clipboard/capture.sh — with
    # #!/bin/bash shebangs that do not resolve on NixOS.
    patchShebangs "$out/bin" "$out/share/omarchy/shell"

    runHook postInstall
  '';

  postFixup = ''
    for script in "$out"/bin/omarchy-*; do
      wrapProgram "$script" \
        --prefix PATH : "$out/bin:${lib.makeBinPath runtimeInputs}" \
        --set-default OMARCHY_PATH "$out/share/omarchy" \
        --set-default TZDIR "${tzdata}/share/zoneinfo"
    done

    # Debug/manual entry point. Session autostart goes through the vendored
    # omarchy-launch-shell instead, which supervises the process, relaunches it
    # if Qt exits without a signal, and tags its log into the journal.
    # omarchy-shell itself only forwards IPC and never starts anything.
    makeWrapper ${lib.getExe quickshell} "$out/bin/omarchy-shell-run" \
      --add-flags "-p $out/share/omarchy/shell" \
      --prefix PATH : "$out/bin:${lib.makeBinPath runtimeInputs}" \
      --set-default OMARCHY_PATH "$out/share/omarchy" \
      --set-default TZDIR "${tzdata}/share/zoneinfo"
  '';

  meta = {
    description = "Bar, OSD and notification slice of the Omarchy 4 Quickshell desktop shell";
    homepage = "https://github.com/basecamp/omarchy";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "omarchy-shell-run";
  };
}

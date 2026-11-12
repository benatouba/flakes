# Adapted from Nixpkgs' MIT-licensed Brave packaging at
# 1d060086d60cb76a40cf37109f979d88a5bd6396.
# This repository now owns release/security updates; see README.md.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  wrapGAppsHook3,
  pkgs,
  commandLineArgs ? "",
}:
let
  libraries = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libGL
    libxkbcommon
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxshmfence
    libxtst
    libuuid
    libgbm
    nspr
    nss
    pango
    pciutils
    pipewire
    udev
    wayland
    libxcb
    zlib
    snappy
    speechd-minimal
    libkrb5
    vulkan-loader
    qt6.qtbase
    libpulseaudio
    libva
  ];
  rpath = lib.makeLibraryPath libraries + ":" + lib.makeSearchPathOutput "lib" "lib64" libraries;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "brave";
  version = "1.99.55";

  src = fetchurl {
    url = "https://github.com/brave/brave-browser/releases/download/v${finalAttrs.version}/brave-browser_${finalAttrs.version}_amd64.deb";
    hash = "sha256-Nk6VSirYTVuj4OIXoinVhzxK5xB9FeYSDkIHUpU5yI0=";
  };

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  doInstallCheck = true;

  nativeBuildInputs = [
    dpkg
    (wrapGAppsHook3.override { makeWrapper = pkgs.makeShellWrapper; })
  ];
  buildInputs = with pkgs; [
    glib
    gsettings-desktop-schemas
    gtk3
    gtk4
    adwaita-icon-theme
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -R usr/share "$out/"
    cp -R opt "$out/"

    browserDir="$out/opt/brave.com/brave"
    substituteInPlace "$browserDir/brave-browser" \
      --replace-fail /bin/bash ${stdenv.shell} \
      --replace-fail CHROME_WRAPPER WRAPPER
    ln -s "$browserDir/brave-browser" "$out/bin/brave"

    for exe in brave chrome_crashpad_handler; do
      patchelf --set-interpreter "$(cat "$NIX_CC/nix-support/dynamic-linker")" \
        --set-rpath ${lib.escapeShellArg rpath} "$browserDir/$exe"
    done

    substituteInPlace "$out/share/applications/"{brave-browser,com.brave.Browser}.desktop \
      --replace-fail /usr/bin/brave-browser-stable "$out/bin/brave"
    substituteInPlace "$out/share/gnome-control-center/default-apps/brave-browser.xml" \
      --replace-fail /opt/brave.com "$out/opt/brave.com"
    substituteInPlace "$browserDir/default-app-block" \
      --replace-fail /opt/brave.com "$out/opt/brave.com"

    for size in 16 24 32 48 64 128 256; do
      mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
      ln -s "$browserDir/product_logo_$size.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/brave-browser.png"
    done

    # ANGLE needs the NixOS Vulkan loader to find /run/opengl-driver ICDs.
    rm "$browserDir/libvulkan.so.1"
    ln -s ${lib.getLib pkgs.vulkan-loader}/lib/libvulkan.so.1 "$browserDir/libvulkan.so.1"
    ln -sf ${pkgs.xdg-utils}/bin/xdg-settings "$browserDir/xdg-settings"
    ln -sf ${pkgs.xdg-utils}/bin/xdg-mime "$browserDir/xdg-mime"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${lib.escapeShellArg rpath}
      --prefix PATH : ${lib.escapeShellArg (lib.makeBinPath libraries)}
      --suffix PATH : ${
        lib.escapeShellArg (
          lib.makeBinPath [
            pkgs.xdg-utils
            pkgs.coreutils
          ]
        )
      }
      --set CHROME_WRAPPER brave
      --add-flags "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder"
      --add-flags "--disable-features=UseChromeOSDirectVideoDecoder"
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
      --add-flags ${lib.escapeShellArg commandLineArgs}
    )
  '';

  installCheckPhase = ''
    runHook preInstallCheck
    # The upstream launcher can suppress errors; check the patched executable.
    "$out/opt/brave.com/brave/brave" --version | grep -F '${finalAttrs.version}'
    test -x "$out/bin/brave"
    grep -F "$out/bin/brave" "$out/share/applications/brave-browser.desktop"
    runHook postInstallCheck
  '';

  meta = {
    description = "Privacy-oriented browser (official Brave release, locally packaged)";
    homepage = "https://brave.com/";
    changelog = "https://github.com/brave/brave-browser/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mpl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "brave";
  };
})

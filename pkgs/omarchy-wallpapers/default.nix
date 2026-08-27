# The wallpapers Omarchy ships with its 22 themes: 92 images, ~52 MB.
#
# Kept as its own derivation rather than folded into pkgs/omarchy-shell so the
# shell itself stays small and the images only enter a closure where something
# actually installs them.
#
# Flattened into one directory and prefixed with the theme name, because the
# random picker in cells/scripts/wallpaper.nix searches with `-maxdepth 1`.
# Prefixing also keeps the several `omarchy.webp` files from colliding.
{
  lib,
  stdenvNoCC,
  omarchySrc,
}:
stdenvNoCC.mkDerivation {
  pname = "omarchy-wallpapers";
  version = "4.0.0-unstable-2026-08-27";

  src = omarchySrc;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    target="$out/share/omarchy/wallpapers"
    mkdir -p "$target"

    found=0
    for dir in themes/*/backgrounds; do
      [ -d "$dir" ] || continue
      theme=$(basename "$(dirname "$dir")")

      for image in "$dir"/*; do
        [ -f "$image" ] || continue
        install -Dm644 "$image" "$target/$theme-$(basename "$image")"
        found=$((found + 1))
      done
    done

    if [ "$found" -eq 0 ]; then
      echo "omarchy-wallpapers: no themes/*/backgrounds found upstream" >&2
      exit 1
    fi

    echo "omarchy-wallpapers: installed $found images"

    runHook postInstall
  '';

  meta = {
    description = "Wallpapers shipped with the Omarchy theme collection";
    homepage = "https://github.com/basecamp/omarchy";
    # The repository is MIT. Individual wallpapers are third-party artwork
    # whose provenance is not tracked upstream, so treat redistribution as
    # unreviewed even though local use is unencumbered.
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}

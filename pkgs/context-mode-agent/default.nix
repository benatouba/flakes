{
  fetchurl,
  nodejs-slim_24,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "context-mode-agent";
  version = "2.2.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/context-mode/-/context-mode-${finalAttrs.version}.tgz";
    hash = "sha256-LoIwmnZFupDyv6R+l4XkwK5g/kfuKhydG/bm9dmGtI4=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R . "$out/"

    # Claude also auto-loads hooks/hooks.json, which is for Gemini.
    rm "$out/hooks/hooks.json"
    substituteInPlace "$out/.claude-plugin/plugin.json" \
      --replace-fail '"command": "node"' '"command": "${nodejs-slim_24}/bin/node"'
    substituteInPlace "$out/hooks/claude-code.json" \
      --replace-fail '"command": "node ' '"command": "${nodejs-slim_24}/bin/node '
    runHook postInstall
  '';
})

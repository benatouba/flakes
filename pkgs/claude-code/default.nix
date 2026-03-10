{ lib
, stdenv
, fetchurl
, nodejs
, makeWrapper
, ripgrep
}:

stdenv.mkDerivation rec {
  pname = "claude-code";
  version = "2.1.72";

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    sha256 = "sha256-4R+JdPZrwJv+BCKwebJb2nMYHLxcyert/FRP5MMXuhI=";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/claude-code $out/bin
    cp -r . $out/lib/claude-code/

    # Replace vendored ripgrep with system ripgrep
    rm -rf $out/lib/claude-code/vendor/ripgrep
    ln -s ${ripgrep}/bin/rg $out/lib/claude-code/vendor/rg

    makeWrapper ${nodejs}/bin/node $out/bin/claude \
      --add-flags "$out/lib/claude-code/cli.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code CLI - an agentic coding tool by Anthropic";
    homepage = "https://github.com/anthropics/claude-code";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "claude";
  };
}

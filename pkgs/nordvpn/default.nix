{
  autoPatchelfHook,
  dpkg,
  fetchurl,
  iproute2,
  iptables,
  lib,
  libcap_ng,
  libidn2,
  libnl,
  makeWrapper,
  procps,
  sqlite,
  stdenv,
  wireguard-tools,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "nordvpn";
  version = "4.6.0";

  src = fetchurl {
    url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_${version}_amd64.deb";
    sha256 = "1qs2r5qbhj64b1yljngabajsipxz3nhq6pmg7hs9cb73mj02zsdp";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    libidn2
    libcap_ng
    libnl
    sqlite
    stdenv.cc.cc.lib
    zlib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib" "$out/share"
    cp -r usr/lib/nordvpn "$out/lib/"
    cp -r usr/share/bash-completion "$out/share/"
    cp -r usr/share/doc "$out/share/"
    cp -r usr/share/icons "$out/share/"
    cp -r usr/share/licenses "$out/share/"
    cp -r usr/share/man "$out/share/"
    cp -r usr/share/zsh "$out/share/"

    install -Dm755 usr/bin/nordvpn "$out/bin/nordvpn-unwrapped"
    install -Dm755 usr/sbin/nordvpnd "$out/bin/nordvpnd"

    makeWrapper "$out/bin/nordvpn-unwrapped" "$out/bin/nordvpn" \
      --prefix PATH : ${
        lib.makeBinPath [
          iproute2
          iptables
          procps
          wireguard-tools
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Official NordVPN command-line client and daemon";
    homepage = "https://nordvpn.com/download/linux/";
    license = lib.licenses.unfree;
    mainProgram = "nordvpn";
    platforms = [ "x86_64-linux" ];
  };
}

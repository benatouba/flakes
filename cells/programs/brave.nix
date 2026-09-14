_: {
  config.my.branches.desktop.nixosModules = [
    (
      { ... }:
      {
        environment.etc."brave/policies/managed/extensions.json".text = builtins.toJSON {
          ExtensionInstallForcelist = [
            "nngceckbapebfimnlniiiahkandclblb"
            "hfjbmagddngcpeloejdejnfgbamkjaeg"
            "eimadpbcbfnmbkopoojfekhnkhdbieeh"
            "fmkadmapgofadopljbjfkapdkoienihi"
            "fcoeoabgfenejglbffodgkkbkcdhcgfn"
          ];
        };
      }
    )
  ];

  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        programs.chromium = {
          enable = true;
          package = pkgs.brave;
          extensions = [
            { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
            { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } # Vimium C
            { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
            { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React Developer Tools
            # Claude in Chrome: lets `claude --chrome` (or `/chrome`) drive the
            # browser to verify web apps. Claude Code writes the native-messaging
            # host manifest into ~/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/
            # itself (persisted via cells/persist/home.nix) and rewrites it when
            # the claude store path changes. Site access is governed by the
            # extension's own per-site permissions; page content of allowed
            # sites is sent to Anthropic.
            { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; }
            { id = "ekhagklcjbdpajgpjgmbionohlpdbjgc"; } # Zotero Connector
            { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsorblock
            { id = "bhlhnicpbhignbdhedgjhgdocnmhomnp"; } # Colorzilla
            { id = "pjjgklgkfeoeiebjogplpnibpfnffkng"; } # Undistracted
          ];
        };
      }
    )
  ];
}

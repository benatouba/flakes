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
            { id = "ekhagklcjbdpajgpjgmbionohlpdbjgc"; } # Zotero Connector
          ];
        };
      }
    )
  ];
}

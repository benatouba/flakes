{ ... }:
{
  config.my.nixosModules = [({ ... }: {
    environment.etc."brave/policies/managed/extensions.json".text =
      builtins.toJSON {
        ExtensionInstallForcelist = [
          "nngceckbapebfimnlniiiahkandclblb"
          "hfjbmagddngcpeloejdejnfgbamkjaeg"
          "eimadpbcbfnmbkopoojfekhnkhdbieeh"
        ];
      };
  })];

  config.my.hmModules = [({ pkgs, ... }: {
    programs.chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } # Vimium C
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      ];
    };
  })];
}

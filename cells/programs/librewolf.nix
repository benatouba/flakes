_: {
  config.my.branches.desktop.hmModules = [
    (
      { lib, pkgs, ... }:
      let
        # Signed release XPIs, not mutable AMO "latest" endpoints. See README.
        addons = builtins.fromJSON (builtins.readFile ./librewolf/addons.json);
        extensionSettings = lib.listToAttrs (
          map (addon: {
            name = addon.id;
            value = {
              installation_mode = "normal_installed";
              install_url = "file://${
                pkgs.fetchurl {
                  name = "${addon.name}-${addon.version}.xpi";
                  inherit (addon) url hash;
                }
              }";
            };
          }) addons
        );
      in
      {
        programs.librewolf = {
          enable = true;
          package = pkgs.librewolf;
          # Preserve upstream hardening, cookie clearing and disabled Sync.
          # Do not manage/import an existing profile or any account credentials.
          policies = {
            DontCheckDefaultBrowser = true;
            ExtensionSettings = extensionSettings;
          };
        };
      }
    )
  ];
}

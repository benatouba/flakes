_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        # Plain nixpkgs waybar on purpose. An overrideAttrs here changes the
        # derivation hash, so no binary cache could serve it and every nixpkgs
        # bump would mean a full C++ rebuild.
        #
        # The config *does* use a group/drawer now (the cpu/memory/disk stats
        # group) and still needs no override: nixpkgs builds waybar with
        # `experimentalPatches ? true`, so -Dexperimental=true is already on in
        # the cached build. An earlier version of this comment said otherwise.
        environment.systemPackages = with pkgs; [
          waybar
        ];
      }
    )
  ];

  config.my.branches.desktop.hmModules = [
    {
      xdg.configFile."waybar" = {
        source = ./waybar;
        recursive = true;
      };
    }
  ];
}

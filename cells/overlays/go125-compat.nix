_: {
  # Shim: aliases.nix binds buildGo125Module to throw (Go 1.25 EOL); alias to buildGoModule.
  # Remove once nixos-unstable catches up with the upstream fix.
  config.my.branches.base.nixosModules = [
    {
      nixpkgs.overlays = [
        (_final: prev: {
          buildGo125Module = prev.buildGoModule;
        })
      ];
    }
  ];
}

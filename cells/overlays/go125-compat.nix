_: {
  # Compatibility shim: nixos-unstable's pkgs/top-level/aliases.nix now binds
  # buildGo125Module to `throw "Go 1.25 is end-of-life..."` (the Go 1.25
  # EOL removal), landing before pkgs.sops (which still references it on this
  # channel) was updated to plain buildGoModule -- already fixed on nixpkgs
  # master, just not yet promoted to nixos-unstable. buildGoXYZModule has
  # always just been buildGoModule pinned to a specific Go version, so
  # unconditionally overriding the throwing alias is a safe stand-in. The `or`
  # form doesn't work here: the attribute exists (bound to a throw), it's not
  # missing, so `prev.buildGo125Module or default` still picks the throwing
  # value. Remove once nixos-unstable catches up with upstream.
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

{ inputs, ... }:
let
  defaultOverlay = inputs.nixpkgs.lib.composeManyExtensions [
    (import ../../pkgs).overlay
    inputs.neovim-nightly.overlays.default
    (final: prev: {
      # Temporary workaround for the dependency hash in pinned Nixpkgs.
      # Keep this scoped; other versions/platforms need their own verification.
      opencode =
        if prev.opencode.version == "2.2.5" && final.stdenv.hostPlatform.system == "x86_64-linux" then
          prev.opencode.overrideAttrs (old: {
            node_modules = old.node_modules.overrideAttrs {
              outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
            };
          })
        else
          prev.opencode;
    })
  ];
in
{
  config.flake.overlays.default = defaultOverlay;

  config.my.branches.base.nixosModules = [
    (
      { ... }:
      {
        nixpkgs = {
          overlays = [
            inputs.self.overlays.default
          ];
        };
      }
    )
  ];
}

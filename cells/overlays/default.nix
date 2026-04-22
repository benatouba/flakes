{ inputs, ... }:
let
  defaultOverlay = inputs.nixpkgs.lib.composeManyExtensions [
    (import ../../pkgs).overlay
    inputs.neovim-nightly.overlays.default
  ];
in
{
  config.flake.overlays.default = defaultOverlay;

  config.my.branches.base.nixosModules = [
    (
      { ... }:
      {
        nixpkgs = {
          overlays = (import ../../overlays) ++ [
            inputs.self.overlays.default
          ];
        };
      }
    )
  ];
}

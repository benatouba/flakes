{ inputs, ... }:
let
  defaultOverlay = inputs.nixpkgs.lib.composeManyExtensions [
    # Source-only flake inputs that pkgs/* derivations take as callPackage
    # arguments. pkgs/default.nix resolves those from `final`, so this has to
    # compose ahead of it.
    (_final: _prev: {
      omarchySrc = inputs.omarchy;
    })
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

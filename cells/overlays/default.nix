{ inputs, ... }:
{
  config.flake.overlays.default = (import ../../pkgs).overlay;

  config.my.branches.base.nixosModules = [
    (
      { ... }:
      {
        nixpkgs = {
          overlays = (import ../../overlays) ++ [
            (import ../../pkgs).overlay
            inputs.neovim-nightly.overlays.default
          ];
        };
      }
    )
  ];
}

{ system, self, nixpkgs, inputs, user, theme, ... }:

let
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true; # Allow proprietary software
  };

  lib = nixpkgs.lib;
in
{
  laptop = lib.nixosSystem {
    # Laptop profile
    inherit system;
    specialArgs = { inherit inputs user theme; };
    modules = [
      ./laptop/wayland
    ] ++ [
      ./system.nix
    ] ++ [
      ../modules/impermanence
    ] ++ [
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2
      inputs.impermanence.nixosModules.impermanence
      inputs.hyprland.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs user theme; };
          users.${user} = {
            imports = [
              (import ./laptop/wayland/home.nix)
            ] ++ [
              (import ../modules/impermanence/home.nix)
            ] ++ [
              inputs.hyprland.homeManagerModules.default
            ];
          };
        };
        nixpkgs = {
          overlays =
            (import ../overlays)
              ++ [
              self.overlays.default
              inputs.neovim-nightly.overlays.default
              # inputs.gdal.overlays.default
            ];
        };
      }
    ];
  };

}

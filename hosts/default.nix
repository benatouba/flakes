{ system, self, nixpkgs, inputs, user, theme, ... }:

let
  inherit (nixpkgs) lib;

  mkHost = { hostModules, hmModules, hardwareModules ? [] }: lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs user theme; };
    modules = [
      ./common/core.nix
      ../modules/nixos/impermanence.nix
      inputs.impermanence.nixosModules.impermanence
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs user theme; };
          users.${user}.imports = hmModules;
        };
        nixpkgs = {
          overlays =
            (import ../overlays)
              ++ [
              self.overlays.default
              inputs.neovim-nightly.overlays.default
            ];
        };
      }
    ] ++ hostModules ++ hardwareModules;
  };
in
{
  laptop = mkHost {
    hostModules = [ ./laptop ];
    hmModules = [
      ./laptop/home.nix
      inputs.hyprland.homeManagerModules.default
    ];
    hardwareModules = [
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2
    ];
  };
}

{
  description = "The most basic configuration";

  inputs =
    {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      hyprpicker.url = "github:hyprwm/hyprpicker";
      hypr-contrib.url = "github:hyprwm/contrib";
      neovim-nightly = {
        url = "github:nix-community/neovim-nightly-overlay";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      hyprland = {
        url = "github:hyprwm/Hyprland";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      impermanence.url = "github:nix-community/impermanence";
      nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    };

  outputs = inputs @ { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      user = "ben";
      themeName = "catppuccin-mocha"; # or "catppuccin-latte"
      theme = import ./lib/theme.nix { inherit themeName; };
      selfPkgs = import ./pkgs;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          inputs.neovim-nightly.overlays.default
        ];
      };
    in
    {
      devShells.${system}.default = import ./shell.nix { inherit pkgs; };

      overlays.default = selfPkgs.overlay;

      nixosConfigurations = import ./hosts {
          inherit system nixpkgs self inputs user theme;
        };
    };
}

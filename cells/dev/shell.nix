{ inputs, ... }:
{
  config.systems = [ "x86_64-linux" ];

  config.perSystem = { pkgs, system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.self.overlays.default
        inputs.neovim-nightly.overlays.default
      ];
    };

    devShells.default = pkgs.mkShell {
      shellHook = ''
              echo "
         ______   _           _
        |  ____| | |         | |
        | |__    | |   __ _  | | __   ___   ___
        |  __|   | |  / _\` | | |/ /  / _ \ / __|
        | |      | | | (_| | |   <  |  __/ \\__ \\
        |_|      |_|  \__,_| |_|\_\  \___| |___/
              "
      '';
      nativeBuildInputs = with pkgs; [
        git
        neovim

        nil
        nixd
        nixfmt
        statix
        deadnix
        nix-diff
        nix-tree
        nix-output-monitor
        nvd

        editorconfig-checker
        commitlint
      ];
    };
  };
}

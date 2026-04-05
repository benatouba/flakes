{ inputs, ... }:
{
  config.systems = [ "x86_64-linux" ];

  config.perSystem =
    {
      pkgs,
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.self.overlays.default
          inputs.neovim-nightly.overlays.default
        ];
      };

      formatter = pkgs.nixfmt;

      checks = {
        deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
          cd ${inputs.self}
          deadnix --fail cells flake.nix
          touch "$out"
        '';

        statix = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
          cd ${inputs.self}
          statix check .
          touch "$out"
        '';

        nixfmt =
          pkgs.runCommand "nixfmt-check"
            {
              nativeBuildInputs = [
                pkgs.findutils
                pkgs.nixfmt
              ];
            }
            ''
              cd ${inputs.self}
              nixfmt --check flake.nix $(find cells secrets -type f -name '*.nix')
              touch "$out"
            '';
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
          nh

          editorconfig-checker
          commitlint
          just
        ];
      };
    };
}

{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
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

    # Nix language tooling
    nil             # LSP server
    nixfmt          # formatter
    statix          # linter — catches antipatterns
    deadnix         # find unused code
    nix-diff        # diff two derivations
    nix-tree        # explore dependency tree
    nix-output-monitor # prettier build output (nom)

    # Linters (used by nvim-lint)
    editorconfig-checker
    commitlint
  ];
}

{ config, lib, pkgs, ... }:

let
  install_lsp = pkgs.writeShellScriptBin "install_lsp" ''
      #!/bin/bash
    if [ ! -d ~/.npm-global ]; then
             mkdir ~/.npm-global
             npm set prefix ~/.npm-global
      else
             npm set prefix ~/.npm-global
    fi
    npm i -g npm vscode-langservers-extracted typescript typescript-language-server bash-language-server
  '';
in
{
  programs = {
    nixneovim = {
      enable = true;
      extraConfigLua = ''
        require("functions")
        require("keymappings")
        require("settings")
      '';
      plugins = {
        firenvim.enable = true;
        lsp = {
          enable = true;
          servers = {
            html.enable = true;
            jsonls.enable = true;
            rnix-lsp.enable = true;
            vuels.enable = true;
          };
        };
        treesitter = {
          enable = true;
          indent = true;
          extraLua.post = ''
            require("language_parsing.treesitter")
          '';
        };
        nvim-cmp = {
          enable = true;
          completion = {
            autocomplete = "true";
          };
          snippet.luasnip.enable = true;
      	};
      };
    };
  };
  home = {
    packages = with pkgs; [
      #-- LSP --#
      install_lsp
      rnix-lsp
      lua-language-server
      gopls
      pyright
      zk
      rust-analyzer
      clang-tools
      #-- tree-sitter --#
      tree-sitter
      #-- format --#
      stylua
      black
      nixpkgs-fmt
      rustfmt
      beautysh
      nodePackages.prettier
      #-- Debug --#
      lldb
    ];
  };

  # home.file.".config/nvim/init.lua".source = ./nvim/init.lua;
  home.file.".config/nvim/lua".source = ./nvim/lua;
}

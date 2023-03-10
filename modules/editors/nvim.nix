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
    neovim = {
      enable = true;
      # package = pkgs.neovim-nightly;
      withPython3 = true;
      withNodeJs = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = false;
      extraLuaConfig = lib.fileContents ./nvim/nixinit.lua;
      plugins = with pkgs; [
        vimPlugins.nvim-treesitter.withAllGrammars
        vimPlugins.packer-nvim
        vimPlugins.telescope-nvim
	];
  extraPackages = with pkgs; [
      tree-sitter
      cargo
    ];
    };
  #   nixvim = {
  #     enable = true;
  #     globals.mapleader = "<space>";
  #     plugins = {
  #       nvim-autopairs.enable = true;
  #       barbar = {
  #         enable = true;
  #         autoHide = true;
  #         animation = true;
  #       };
  #       comment = {
  #         enable = true;
  #         extraLua.pre = "require('base.comment_nvim').config()";
  #       };
  #       firenvim.enable = true;
  #       indent-blankline.enable = true;
  #       undotree.enable = true;
  #       lsp = {
  #         enable = true;
  #         servers = {
  #           html.enable = true;
  #           jsonls.enable = true;
  #           rnix-lsp.enable = true;
  #           # lua_ls.enable = true;
  #           vuels.enable = true;
  #         };
  #       };
  #       lualine = {
  #         enable = true;
  #       };
  #       project-nvim = {
  #         enable = true;
  #       };
  #       telescope = {
  #         enable = true;
  #         useBat = true;
  #         extensions = {
  #           manix.enable = true;
  #         };
  #       };
  #       nvim-tree = {
  #         enable = true;
  #       };
  #       treesitter = {
  #         enable = true;
  #         indent = true;
  #         installAllGrammars = true;
  #         extraLua.post = ''
  #           require("language_parsing.treesitter")
  #         '';
  #       };
  #       luasnip.enable = true;
  #       lspkind.enable = true;
  #       nvim-cmp = {
  #         enable = true;
  #         snippet.luasnip.enable = true;
  #         sources = {
  #           buffer.enable = true;
  #           cmdline.enable = true;
  #           dap.enable = true;
  #           emoji.enable = true;
  #           git.enable = true;
  #           look.enable = true;
  #           luasnip.enable = true;
  #           nvim_lsp.enable = true;
  #           nvim_lua.enable = true;
  #           path.enable = true;
  #           rg.enable = true;
  #           tmux.enable = true;
  #           treesitter.enable = true;
  #         };
  #       };
  #       nvim-dap.enable = true;
  #       nvim-dap-ui.enable = true;
  #       trouble.enable = true;
  #       neogit.enable = true;
  #       gitsigns = {
  #         enable = true;
  #         extraLua.post = "require('git.gitsigns')";
  #       };
  #       todo-comments = {
  #         enable = true;
  #         extraLua.post = "require('todo-comments').setup()";
  #       };
  #     };
  #     extraPlugins = with pkgs.vimExtraPlugins; [
  #       which-key-nvim
  #       lsp-status-nvim
  #       catppuccin
  #       cmp-under-comparator
  #       dial-nvim
  #       nvim-surround
  #       lsp-signature-nvim
  #       nvim-ts-context-commentstring
  #       nvim-lsp-ts-utils
  #       nvim-bqf
  #       toggleterm-nvim
  #       neogen
  #       nvim-hlslens
  #     ];
  #   };
  # };
  # home = {
  #   packages = with pkgs; [
  #     #-- LSP --#
  #     install_lsp
  #     rnix-lsp
  #     lua-language-server
  #     gopls
  #     pyright
  #     python3Packages.python-lsp-server
  #     python3Packages.pylsp-mypy
  #     python3Packages.pyls-isort
  #     python3Packages.python-lsp-black
  #     python3Packages.pyls-flake8
  #     zk
  #     rust-analyzer
  #     clang-tools
  #     nil
	 #  taplo
  #     #-- tree-sitter --#
  #     tree-sitter
  #     #-- format --#
  #     stylua
  #     black
  #     nixpkgs-fmt
  #     rustfmt
  #     beautysh
  #     nodePackages.prettier
  #     #-- Debug --#
  #     lldb
  #   ];
  # };
  #
  # # home.file.".config/nvim/init.lua".source = ./nvim/init.lua;
  # home.file.".config/nvim".source = ./nvim;
};
}

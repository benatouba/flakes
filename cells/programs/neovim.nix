{ config, lib, ... }:
let
  user = config.my.user.name;
in
{
  config.my.branches.desktop.hmModules = [
    (
      { config, pkgs, ... }:
      let
        nvimConfigPath = "/home/${user}/projects/nvim";
      in
      {
        programs.neovim = {
          enable = true;
          defaultEditor = true;
          package = pkgs.neovim-unwrapped;
          initLua = lib.mkForce "";
          viAlias = true;
          vimAlias = true;
          withNodeJs = true;
          withPython3 = true;
          withRuby = false;
          extraWrapperArgs = [
            "--set"
            "DIRENV_LOG_FORMAT"
            ""
          ];
          extraPackages = with pkgs; [
            bash-language-server
            fortls
            hyprls
            lemminx
            lua-language-server
            matlab-language-server
            nil
            nixd
            nginx-language-server
            postgres-language-server
            sqls
            texlab
            tinymist
            vim-language-server
            yaml-language-server

            docker-language-server
            marksman
            taplo

            texlivePackages.latexindent
            nixfmt
            prettier
            prettierd
            stylua
            typstyle
            xmlformat
            yamlfmt

            actionlint
            codespell
            commitlint
            editorconfig-checker
            markdownlint-cli
            proselint
            selene

            vscode-js-debug

            tree-sitter
            gcc
            gnumake
            fd
            ripgrep

            cmake
            cargo
          ];
        };

        xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimConfigPath;
      }
    )
  ];
}

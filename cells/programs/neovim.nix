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
            # copilot.lua's default is to download GitHub's glibc-linked
            # native server, which cannot exec on NixOS.  The nvim config
            # points `server.custom_server_filepath` at this one instead.
            copilot-language-server

            nil
            nixd
            nixfmt
            statix

            commitlint
            editorconfig-checker

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

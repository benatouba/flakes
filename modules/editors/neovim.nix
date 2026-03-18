{
  config,
  pkgs,
  user,
  ...
}:

let
  nvimConfigPath = "/home/${user}/projects/nvim";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    package = pkgs.neovim; # nightly via neovim-nightly-overlay
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    extraPackages = with pkgs; [
      bash-language-server # Bash
      fortls # Fortran
      hyprls # Hyprland config
      lemminx # XML
      ltex-ls-plus # Grammar checking
      lua-language-server # Lua
      matlab-language-server # MATLAB
      nil # Nix
      nginx-language-server # Nginx
      postgres-language-server # PostgreSQL
      sqls # SQL
      texlab # LaTeX
      tinymist # Typst
      vim-language-server # Vim
      yaml-language-server # YAML

      # -- Formatters --
      texlivePackages.latexindent # LaTeX
      nixfmt # Nix
      stylua # Lua
      typstyle # Typst
      xmlformat # XML
      yamlfmt # YAML

      # -- Linters --
      actionlint # GitHub Actions
      codespell # Spell checker
      commitlint # Git commit messages
      editorconfig-checker # EditorConfig
      proselint # Prose
      selene # Lua

      # -- Debug --
      vscode-js-debug # JS/TS debug adapter

      # -- Supporting tools --
      tree-sitter # Parser generator
      gcc # Needed by treesitter to compile parsers
      gnumake # Build tool for parsers
      fd # Used by telescope
      ripgrep # Used by telescope + conform
      # fzf # Used by telescope

      # --- for compilation ---
      cmake
      gnumake
      gcc
      cargo
    ];
  };

  # Symlink directly to the local nvim repo — editable, no rebuild needed
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimConfigPath;
}

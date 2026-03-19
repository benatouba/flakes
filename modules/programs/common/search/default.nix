{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fd
  ];

  programs = {
    fzf.enable = true;

    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns=150"
        "--max-columns-preview"
        "--type-add=web:*.{html,css,js}*"
        "--glob=!git/*"
        "--colors=line:none"
        "--colors=line:style:bold"
        "--smart-case"
      ];
    };
  };
}

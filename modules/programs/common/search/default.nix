{ config, pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      fd
      ripgrep
    ];
  };
  programs = {
    fzf.enable = true;
  };
}

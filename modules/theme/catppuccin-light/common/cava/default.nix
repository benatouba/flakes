{ config, pkgs, lib, ... }:
{
  home.file.".config/cava/config".source = lib.mkDefault ./config;
  home.file.".config/cava/config1".source = lib.mkDefault ./config1;
}

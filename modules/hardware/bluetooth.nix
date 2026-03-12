{ config, lib, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  services.blueman.enable = true;
  # systemd.user.services.mpris-proxy = {
  #   Unit.Description = "Mpris proxy";
  #   Unit.After = [ "network.target" "sound.target" ];
  #   Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  #   Install.WantedBy = [ "default.target" ];
  # };
}

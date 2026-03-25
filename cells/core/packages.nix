{ ... }:
{
  config.my.nixosModules = [({ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      curl
      eza
      fzf
      git
      killall
      libglvnd
      lshw
      pciutils
      socat
      wget
    ];
  })];
}

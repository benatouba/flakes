_: {
  config.my.branches.base.nixosModules = [
    (
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          curl
          dnsutils
          eza
          fzf
          git
          killall
          libglvnd
          lshw
          lsof
          pciutils
          unzip
          socat
          wget
          zip
        ];
      }
    )
  ];
}

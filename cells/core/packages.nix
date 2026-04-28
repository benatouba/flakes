_: {
  config.my.branches.base.nixosModules = [
    (
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          curl
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

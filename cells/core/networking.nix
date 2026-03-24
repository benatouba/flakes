{ ... }:
{
  config.my.nixosModules = [({ pkgs, ... }: {
    services = {
      openssh.enable = true;
      dbus.enable = true;
    };

    programs.zsh.enable = true;

    environment.etc."brave/policies/managed/extensions.json".text =
      builtins.toJSON {
        ExtensionInstallForcelist = [
          "nngceckbapebfimnlniiiahkandclblb"
          "hfjbmagddngcpeloejdejnfgbamkjaeg"
        ];
      };

    environment = {
      binsh = "${pkgs.dash}/bin/dash";
      shells = with pkgs; [ zsh ];
      systemPackages = with pkgs; [
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
    };
  })];
}

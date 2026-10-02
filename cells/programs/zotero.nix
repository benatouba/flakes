_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        # TODO: re-enable once nixpkgs fixes zotero (Gecko 140 ESR vs esr-153 patch fail).
        # Disabled to unblock rebuild; use Flatpak/upstream tarball meanwhile.
        environment.systemPackages = with pkgs; [
        ];
      }
    )
  ];
}

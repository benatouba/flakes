_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          zotero
        ];
      }
    )
  ];
}

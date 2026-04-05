_: {
  config.my.branches.base.nixosModules = [
    {
      programs.command-not-found.enable = false;
    }
  ];

  config.my.branches.base.hmModules = [
    {
      programs.nix-index = {
        enable = true;
        enableZshIntegration = true;
      };
    }
  ];
}

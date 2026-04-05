{ ... }:
{
  config.my.nixosModules = [{
    programs.command-not-found.enable = false;
  }];

  config.my.hmModules = [{
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  }];
}

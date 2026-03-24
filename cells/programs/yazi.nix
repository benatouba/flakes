{ ... }:
{
  config.my.hmModules = [{
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      settings = {
        manager = {
          show_hidden = true;
        };
      };
    };
  }];
}

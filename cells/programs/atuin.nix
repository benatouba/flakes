_: {
  config.my.branches.desktop.hmModules = [
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          style = "compact";
          inline_height = 20;
        };
      };
    }
  ];
}

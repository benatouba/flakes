{ ... }:
{
  config.my.hmModules = [{
    home.file.".commitlintrc.yaml".source = ./commitlint/commitlintrc.yaml;
  }];
}

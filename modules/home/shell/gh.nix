_:
{
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
        pl = "pr list";
        pc = "pr create";
        rv = "repo view";
        rc = "repo clone";
        il = "issue list";
        iv = "issue view";
        ic = "issue create";
      };
    };
  };

  programs.gh-dash.enable = true;
}

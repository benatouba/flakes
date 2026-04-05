_: {
  # Bash is enabled as a fallback shell — zsh is the primary shell.
  # This ensures bash has a valid profile even when used non-interactively.
  config.my.branches.base.hmModules = [
    {
      programs.bash.enable = true;
    }
  ];
}

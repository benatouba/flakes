{ inputs, ... }:
{
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        # Use the upstream CLI without injecting local routing or guard plugins.
        # Preserve independently installed plugins, settings and credentials.
        home.packages = [ inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default ];

        # Global Claude Code conventions, applied across every project unless
        # a repository's own CLAUDE.md overrides them.
        home.file.".claude/CLAUDE.md" = {
          source = ./claude/CLAUDE.md;
          force = true;
        };
      }
    )
  ];
}

{ inputs, ... }:
{
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
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

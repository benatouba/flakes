_: {
  config.my.branches.desktop.hmModules = [
    (
      { lib, pkgs, ... }:
      let
        upstream = pkgs.fetchFromGitHub {
          owner = "K-Dense-AI";
          repo = "scientific-agent-skills";
          rev = "ec59a29a03d5c40f73ab40878df04860bc00e876";
          hash = "sha256-VdBhkQDttOQ5HKGopsNywoTbVGowl1JCzJtIQ6KtWew=";
        };
        selected = [
          "exploratory-data-analysis"
          "scientific-visualization"
          "statistical-analysis"
        ];
      in
      {
        # Both clients discover ~/.claude/skills. Link individual directories
        # so references/scripts work without loading the rest of the catalog.
        home.file =
          lib.genAttrs (map (name: ".claude/skills/${name}") selected) (target: {
            source = "${upstream}/skills/${baseNameOf target}";
          })
          // {
            ".claude/skills/scientific-reproducibility".source = ./scientific-skills/scientific-reproducibility;
          };
      }
    )
  ];
}

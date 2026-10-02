{ inputs, ... }:
{
  # Skills at ~/.claude/skills from upstream plugin.json; tracks flake updates.
  # No plugin install (duplicates); grill-* commands call the grilling primitive.
  config.my.branches.desktop.hmModules = [
    (
      { lib, ... }:
      let
        src = inputs.mattpocock-skills;
        manifest = lib.importJSON "${src}/.claude-plugin/plugin.json";

        # Upstream skills to leave out, by directory name.
        excluded = [ ];

        skillPaths = lib.filter (rel: !(lib.elem (baseNameOf rel) excluded)) (
          map (lib.removePrefix "./") manifest.skills
        );
        names = map baseNameOf skillPaths;
      in
      {
        assertions = [
          {
            assertion = lib.length names == lib.length (lib.unique names);
            message = "mattpocock-skills: duplicate skill directory names in upstream plugin.json";
          }
        ];

        home.file = lib.listToAttrs (
          map (rel: {
            name = ".claude/skills/${baseNameOf rel}";
            value = {
              source = "${src}/${rel}";
              force = true;
            };
          }) skillPaths
        );
      }
    )
  ];
}

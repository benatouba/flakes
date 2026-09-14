{ inputs, ... }:
{
  # Pin Matt Pocock's agent skills and expose them at ~/.claude/skills, the
  # personal-skills directory both Claude Code and OpenCode read. Linking the
  # same names under ~/.agents/skills too would duplicate them in OpenCode.
  #
  # The set is derived from upstream's `.claude-plugin/plugin.json`, so it is
  # exactly what `/plugin install mattpocock-skills` would install, and it
  # follows upstream on `nix flake update` without editing a list here. Do not
  # also install the plugin: the README warns that both leave every skill twice.
  #
  # Naming, for the grill family: `grilling` is the model-invocable interview
  # primitive; `grill-me` and `grill-with-docs` are the user-typed commands
  # that call it (the latter also calls `domain-modeling`).
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

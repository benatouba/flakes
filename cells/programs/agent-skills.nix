{ inputs, ... }:
{
  config.my.branches.desktop.hmModules = [
    (
      { lib, pkgs, ... }:
      let
        # Lockfile updates refresh these skills, not the list of installed IDs.
        # Keep the previous Matt Pocock manifest selection explicit.
        mattPocock =
          group: names: lib.genAttrs names (name: "${inputs.mattpocock-skills}/skills/${group}/${name}");
        scientific = lib.genAttrs [
          "exploratory-data-analysis"
          "scientific-visualization"
          "scientific-writing"
          "statistical-analysis"
        ] (name: "${inputs.scientific-agent-skills}/skills/${name}");
        guide = inputs.ai-developer-guide;
        guideSkill = pkgs.runCommand "ai-developer-guide-skill" { } ''
          mkdir -p "$out"
          ln -s ${./agent-skills/ai-developer-guide/SKILL.md} "$out/SKILL.md"
          ln -s ${guide}/README.md ${guide}/guides ${guide}/LICENSE "$out/"
          test -s "$out/README.md"
          test -d "$out/guides"
        '';
        notebook = "${inputs.openai-skills}/skills/.curated/jupyter-notebook";
        notebookSkill = pkgs.runCommand "jupyter-notebook-skill" { } ''
          mkdir -p "$out"
          cp -R ${notebook}/. "$out/"
          chmod u+w "$out/SKILL.md"
          substituteInPlace "$out/SKILL.md" \
            --replace-fail 'export CODEX_HOME="''${CODEX_HOME:-$HOME/.codex}"' '# Run with the project’s existing Python environment.' \
            --replace-fail '$CODEX_HOME/skills/jupyter-notebook' '$HOME/.claude/skills/jupyter-notebook' \
            --replace-fail 'User-scoped skills install under `$CODEX_HOME/skills` (default: `~/.codex/skills`).' \
              'Use the installed skill directory; the examples use the shared Home Manager path.' \
            --replace-fail 'uv run --python 3.12 python' 'python3' \
            --replace-fail 'Prefer `uv` for dependency management.' \
              'Use available project tools. Ask before downloading Python, packages, or data.' \
            --replace-fail 'uv pip install jupyterlab ipykernel' '# Optional packages: jupyterlab and ipykernel.'
        '';
        sources = lib.mergeAttrsList [
          (mattPocock "engineering" [
            "ask-matt"
            "code-review"
            "codebase-design"
            "diagnosing-bugs"
            "domain-modeling"
            "grill-with-docs"
            "implement"
            "implement-spec"
            "improve-codebase-architecture"
            "pr"
            "prototype"
            "research"
            "retro"
            "setup-matt-pocock-skills"
            "tdd"
            "to-spec"
            "to-tickets"
            "triage"
            "wayfinder"
            "wizard"
          ])
          (mattPocock "productivity" [
            "grill-me"
            "grilling"
            "handoff"
            "teach"
            "to-questionnaire"
            "wait-what"
            "writing-for-agents"
          ])
          scientific
          {
            climate-data-cmip = ./agent-skills/climate-data-cmip;
            climate-model-evaluation = ./agent-skills/climate-model-evaluation;
            climate-paper-planning = ./agent-skills/climate-paper-planning;
            cloudflare = "${inputs.cloudflare-skills}/skills/cloudflare";
            find-skills = "${inputs.vercel-skills}/skills/find-skills";
            jupyter-notebook = notebook;
            scientific-reproducibility = ./scientific-skills/scientific-reproducibility;
          }
        ];
        skills = sources // {
          agent-browser = "${pkgs.agent-browser}/skills/agent-browser";
          ai-developer-guide = guideSkill;
          jupyter-notebook = notebookSkill;
        };
        root = ".claude/skills";
      in
      {
        # One link per skill preserves references and serves both harnesses.
        home.file = lib.mapAttrs' (
          name: source: lib.nameValuePair "${root}/${name}" { inherit source; }
        ) skills;

        assertions = lib.mapAttrsToList (
          name: source:
          let
            entry = "${source}/SKILL.md";
            parts = lib.splitString "\n---" (builtins.readFile entry);
            header = lib.head parts;
            names = lib.filter (lib.hasPrefix "name:") (lib.splitString "\n" header);
          in
          {
            assertion =
              builtins.pathExists entry
              && lib.length parts > 1
              && lib.hasPrefix "---\n" header
              && builtins.elem names [
                [ "name: ${name}" ]
                [ "name: \"${name}\"" ]
                [ "name: '${name}'" ]
              ];
            message = "Agent skill ${name} is missing SKILL.md or its expected frontmatter name.";
          }
        ) (sources // { ai-developer-guide = ./agent-skills/ai-developer-guide; });

        # ThinkPad enables HM backups. Reject unmanaged skill directories and
        # symlinks before the generic link check can back up or replace them.
        home.activation.checkAgentSkillCollisions = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          for parent in "$HOME/.claude" "$HOME/${root}"; do
            if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
              errorEcho "Expected a real directory for agent skills: $parent"
              exit 1
            fi
          done
          currentSkillFiles="$(readlink -e -- "$newGenPath/home-files")"
          previousSkillFiles=
          if [[ -v oldGenPath ]]; then
            previousSkillFiles="$(readlink -e -- "$oldGenPath/home-files" || true)"
          fi
          for skill in ${lib.escapeShellArgs (builtins.attrNames skills)}; do
            relative="${root}/$skill"
            target="$HOME/$relative"
            if [[ ! -e "$target" && ! -L "$target" ]]; then
              continue
            fi
            if [[ -L "$target" ]]; then
              link="$(readlink -- "$target")"
              # Allow rerunning a generation that linked files before failing.
              if [[ "$link" == "$currentSkillFiles/$relative" ||
                    ( -n "$previousSkillFiles" && -L "$previousSkillFiles/$relative" &&
                      "$link" == "$previousSkillFiles/$relative" ) ]]; then
                continue
              fi
            fi
            errorEcho "Unmanaged skill in the way: $target. Move it aside before activating."
            exit 1
          done
        '';
      }
    )
  ];
}

{ inputs, ... }:
{
  config.my.branches.desktop.hmModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        jevRouter = config.my.jev.router or null;
        jevControl = config.my.jev.control or null;
        claude = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
        controlExe = if jevControl != null then lib.getExe jevControl else "disabled";

        # Local safety controls: tool/prompt guards, final 5.5 allowlist clamp
        # and compaction scheduling. Renamed from jev-router because model
        # selection moved to the vendored upstream selector below; both plugins
        # load side by side, but only one selector owns each turn.
        controlsPlugin = pkgs.runCommand "claude-jev-controls" { } ''
          mkdir -p $out/.claude-plugin $out/hooks
          cp ${./jev-router/claude/.claude-plugin/plugin.json} $out/.claude-plugin/plugin.json
          substitute ${./jev-router/claude/hooks/hooks.json} $out/hooks/hooks.json \
            --replace-fail '@control@' '${controlExe}'
          cp ${./jev-router/README.md} $out/README.md
          substitute ${./jev-router/claude/hooks/register.js} $out/hooks/register.js \
            --replace-fail '@control@' '${controlExe}'
        '';

        # Vendored upstream model selector at a pinned commit (MIT). Local
        # patches harden the payload boundary (prompt-only, no subagent task
        # text, 5.5-only pool) and read the TypeSafe key through the SOPS-backed
        # helper so the credential never enters the Claude process environment
        # where child processes could read it.
        jevRouterUpstream = pkgs.fetchFromGitHub {
          owner = "dominicrico";
          repo = "jev-router";
          rev = "57cde5799e66d10a6e6164a639ecbee11ebe82b6";
          sha256 = "1cvzq7jv45cgrs8hnyk5lpjr89gv2268wamy86684vbvywlckbdh";
        };
        upstreamPlugin =
          pkgs.runCommand "claude-jev-router-upstream" { nativeBuildInputs = [ pkgs.jq ]; }
            ''
              mkdir -p $out/.claude-plugin $out/hooks $out/types
              cp ${jevRouterUpstream}/.claude-plugin/plugin.json $out/.claude-plugin/plugin.json
              cp ${jevRouterUpstream}/.claude-plugin/icon.png $out/.claude-plugin/icon.png
              cp ${jevRouterUpstream}/hooks/hooks.json $out/hooks/hooks.json
              cp ${jevRouterUpstream}/types/index.d.ts $out/types/index.d.ts
              cp ${jevRouterUpstream}/LICENSE $out/LICENSE
              cp ${jevRouterUpstream}/README.md $out/README.md

              # Keep the settings UI aligned with the hardened runtime defaults.
              jq '.userConfig.models.default = ["haiku","sonnet","opus"]
                | .userConfig.models.description = "Aliases Jev may choose from: haiku, sonnet, opus (current 5.5 generation only)"
                | .userConfig.sendHistory.default = false
                | .userConfig.routeSubagents.default = false' \
                $out/.claude-plugin/plugin.json > plugin.json.tmp
              mv plugin.json.tmp $out/.claude-plugin/plugin.json

              substitute ${jevRouterUpstream}/hooks/register.tsx $out/hooks/register.tsx \
                --replace-fail ${lib.escapeShellArg "const allowed = (Array.isArray(options.models) ? options.models : Object.keys(CLAUDE))"} \
                  ${lib.escapeShellArg "const allowed = ['haiku', 'sonnet', 'opus'] // repository policy: 5.5 only"} \
                --replace-fail ${lib.escapeShellArg "pool: allowed.length > 0 ? allowed : Object.keys(CLAUDE),"} \
                  ${lib.escapeShellArg "pool: allowed,"} \
                --replace-fail ${lib.escapeShellArg "sendHistory: flag(options.sendHistory, true),"} \
                  ${lib.escapeShellArg "sendHistory: false, // repository policy: prompt-only payloads"} \
                --replace-fail ${lib.escapeShellArg "routeSubagents: flag(options.routeSubagents, true),"} \
                  ${lib.escapeShellArg "routeSubagents: false, // repository policy: no subagent task text"} \
                --replace-fail ${lib.escapeShellArg "  const stored = await $.store.get('apiKey')"} \
                  ${lib.escapeShellArg "  const helperKey = await $.process.run(['${controlExe}', '--emit-key'], { timeoutMs: 3000 }).then(r => r.exitCode === 0 && typeof r.stdout === 'string' ? r.stdout.trim() : null).catch(() => null); if (helperKey) return { key: helperKey, source: 'SOPS credential helper' }; const stored = await $.store.get('apiKey')"}
            '';
        wrappedClaude = pkgs.symlinkJoin {
          name = "claude-code-jev";
          paths = [ claude ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/claude \
              --prefix CLAUDE_CODE_PLUGIN_DIRS : "${upstreamPlugin}:${controlsPlugin}"
          '';
        };
      in
      {
        # Preserve mutable user settings, credentials and existing plugin paths.
        home.packages = [ (if jevRouter != null then wrappedClaude else claude) ];

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

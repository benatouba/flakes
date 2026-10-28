{
  inputs,
  lib,
  ...
}:
let
  secretsRoot = toString inputs.nix-secrets;
  defaultSopsFile = "${secretsRoot}/secrets.yaml";
  secretName = "typesafe_api_key";
  jevMcpSource = "github:codaaiteam/jev-mcp#6cfb78daa00d405b76f8fee221b559cbb73563a8";
  hasTypesafeApiKey =
    builtins.pathExists defaultSopsFile
    && lib.hasInfix "${secretName}:" (builtins.readFile defaultSopsFile);
in
{
  config.my.branches.personal.hmModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        jevMcp = pkgs.writeShellScriptBin "jev-mcp" ''
          secret=${lib.escapeShellArg config.sops.secrets.${secretName}.path}
          if [ ! -r "$secret" ] || [ ! -s "$secret" ]; then
            printf '%s\n' "jev-mcp: SOPS secret is unavailable or empty: $secret" >&2
            exit 1
          fi

          export TYPESAFE_API_KEY="$(< "$secret")"
          export JEV_BASE_URL="https://api.typesafe.ai/v1/systemone"
          exec ${pkgs.nodejs_latest}/bin/npx -y ${jevMcpSource}
        '';
      in
      {
        options.my.jev.package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
          internal = true;
          description = "Runtime-credential wrapper available to Jev MCP consumers.";
        };

        config = {
          warnings = lib.optional (!hasTypesafeApiKey) ''
            Jev MCP is disabled because `${secretName}` is missing from ${defaultSopsFile}.
            Add it with:
              sops ~/.local/secrets/secrets.yaml   # ${secretName}: <TypeSafe API key>
              just update-secrets
          '';
        }
        // lib.optionalAttrs hasTypesafeApiKey {
          sops.secrets.${secretName} = { };

          # Only this process tree receives the key, read from SOPS at runtime.
          my.jev.package = jevMcp;
          home.packages = [
            jevMcp
          ];
        };
      }
    )
  ];
}

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
      {
        warnings = lib.optional (!hasTypesafeApiKey) ''
          OpenCode Jev MCP is configured, but `${secretName}` is missing from ${defaultSopsFile}.
          Add it with:
            sops ~/.local/secrets/secrets.yaml   # ${secretName}: <TypeSafe API key>
            just update-secrets
        '';
      }
      // lib.optionalAttrs hasTypesafeApiKey {
        sops.secrets.${secretName} = { };

        # Keep the credential out of the general shell environment. OpenCode
        # launches this wrapper as the Jev MCP server, so only that process tree
        # receives the key; the value remains in the sops-nix runtime file.
        home.packages = [
          (pkgs.writeShellScriptBin "jev-mcp" ''
            secret=${config.sops.secrets.${secretName}.path}
            if [ ! -r "$secret" ]; then
              printf '%s\n' "jev-mcp: SOPS secret is unavailable: $secret" >&2
              exit 1
            fi

            export TYPESAFE_API_KEY="$(< "$secret")"
            exec ${pkgs.nodejs_latest}/bin/npx -y ${jevMcpSource}
          '')
        ];
      }
    )
  ];
}

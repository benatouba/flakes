{
  inputs,
  lib,
  ...
}:
let
  secretsRoot = toString inputs.nix-secrets;
  defaultSopsFile = "${secretsRoot}/secrets.yaml";
  secretName = "railway_api_token";

  # sops keys stay plaintext; guard so a missing token warns instead of failing.
  hasRailwayToken =
    builtins.pathExists defaultSopsFile
    && lib.hasInfix "${secretName}:" (builtins.readFile defaultSopsFile);
in
{
  config.my.branches.personal.hmModules = [
    (
      { config, lib, ... }:
      {
        warnings = lib.optional (!hasRailwayToken) ''
          Railway: `${secretName}` is missing from ${defaultSopsFile}, so
          RAILWAY_API_TOKEN will not be exported. Add it with:
            sops ~/.local/secrets/secrets.yaml   # ${secretName}: <token>
            just update-secrets
        '';
      }
      // lib.optionalAttrs hasRailwayToken {
        sops.secrets.${secretName} = { };

        # Token stands in for `railway login`; survives reboot, no ~/.railway state.
        # Only a symlink in $HOME; decrypted value stays on tmpfs.
        programs.zsh.initContent = lib.mkAfter ''
          if [ -r ${config.sops.secrets.${secretName}.path} ]; then
            export RAILWAY_API_TOKEN="$(< ${config.sops.secrets.${secretName}.path})"
          fi
        '';
      }
    )
  ];
}

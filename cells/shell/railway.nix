{
  inputs,
  lib,
  ...
}:
let
  secretsRoot = toString inputs.nix-secrets;
  defaultSopsFile = "${secretsRoot}/secrets.yaml";
  secretName = "railway_api_token";

  # sops encrypts values but leaves mapping keys in plaintext, so the key can be
  # probed without decrypting. Without this guard a rebuild hard-fails at
  # activation until the token is added to the secrets repo.
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

        # RAILWAY_API_TOKEN stands in for `railway login` session state, so the
        # CLI authenticates from sops in every shell — including devenv shells,
        # which inherit the environment. This is what makes logins survive a
        # reboot without persisting ~/.railway/config.json.
        #
        # Only the symlink lives in $HOME; sops-nix keeps the decrypted value on
        # tmpfs under XDG_RUNTIME_DIR, so the token never hits persistent disk.
        programs.zsh.initContent = lib.mkAfter ''
          if [ -r ${config.sops.secrets.${secretName}.path} ]; then
            export RAILWAY_API_TOKEN="$(< ${config.sops.secrets.${secretName}.path})"
          fi
        '';
      }
    )
  ];
}

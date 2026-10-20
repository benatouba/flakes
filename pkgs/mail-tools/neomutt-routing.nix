{ lib }:
{ accounts, configDirectory }:
let
  quote =
    value: ''"${builtins.replaceStrings [ "\\" "\"" "$" "`" ] [ "\\\\" "\\\"" "\\$" "\\`" ] value}"'';
  addresses = lib.unique (
    lib.concatMap (account: [ account.address ] ++ account.aliases) (lib.attrValues accounts)
  );
  hook =
    name: account:
    let
      identities = lib.concatStringsSep "|" (
        map lib.escapeRegex ([ account.address ] ++ account.aliases)
      );
      pattern = "~f ${quote "(^|[<[:space:]])(${identities})(>|[[:space:]]|$)"}";
    in
    "send-hook ${quote pattern} ${quote "source ${configDirectory}/${name}"}";
in
''
  alternates ${lib.concatMapStringsSep " " (address: quote "^${lib.escapeRegex address}$") addresses}
''
+ lib.concatMapStrings (line: "${line}\n") (lib.mapAttrsToList hook accounts)

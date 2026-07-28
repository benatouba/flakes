{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.dns = {
    localRecords = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        "workout.benrlschmidt.de" = "192.168.188.197";
      };
      description = ''
        Split-horizon A records served to LAN clients, as a mapping of fully
        qualified name to LAN address. These override whatever public DNS says
        for the same name.

        Use this for services that are published on a public domain but live on
        this network. Without an override, LAN clients resolve the public
        address and have to be bounced back inside by the router's NAT hairpin,
        which also means a stale negative cache upstream can make a service that
        is running perfectly well look unreachable from home. Pointing the name
        straight at the LAN address removes both dependencies. TLS still
        verifies, because the reverse proxy selects its certificate by SNI
        rather than by the address the client connected to.
      '';
    };
  };
}

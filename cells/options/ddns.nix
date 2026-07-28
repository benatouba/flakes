{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.ddns = {
    hostname = mkOption {
      type = types.str;
      default = "";
      example = "esprimo-benrlschmidt.dedyn.io";
      description = ''
        The deSEC dynDNS hostname to keep pointed at this machine's public IPv4
        address, as registered at https://desec.io/. This is the name the
        updater writes to, not the name users visit; publish the user-facing
        name as a CNAME onto this one.
      '';
    };

    updateEndpoint = mkOption {
      type = types.str;
      default = "https://update.dedyn.io/";
      description = "deSEC dynDNS update endpoint.";
    };

    ipEchoUrl = mkOption {
      type = types.str;
      default = "https://checkipv4.dedyn.io/";
      description = ''
        Service that echoes back the caller's public IPv4 address, used only for
        logging and for sending an explicit `myipv4`. If it is unreachable the
        update still proceeds and deSEC derives the address from the connection
        source, so this is a convenience rather than a dependency.
      '';
    };

    manageIpv6 = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to publish an AAAA record as well as an A record.

        Left off by default: this host receives a Deutsche Telekom prefix that
        rotates on reconnect and uses IPv6 privacy extensions, so the address is
        unstable, and inbound IPv6 is not forwarded by the router. Publishing a
        AAAA that nothing answers on makes IPv6-capable clients and ACME
        validators try a dead path first, so the updater actively deletes any
        stale AAAA instead of leaving it to rot.
      '';
    };

    interval = mkOption {
      type = types.str;
      default = "5min";
      description = "How often to re-check and republish the public IPv4 address.";
    };
  };
}

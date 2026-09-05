# Share the current Wi-Fi as a QR code.
#
# Reachable from the waybar network menu ("Share Wi-Fi…"), and usable on its
# own from a terminal. Read-only and unprivileged: it asks NetworkManager for
# the active connection's secrets, which the owning user may already read.
#
# The awkward parts of building a WIFI: URI, all of which this handles, are
# lifted from Omarchy's omarchy-network-qr:
#
#   * nmcli localises connection state names, so any parsing of them has to
#     pin LC_ALL=C.
#   * `--escape no` matters: the default escapes ":" and "\" in values, which
#     are exactly the characters the URI format also escapes, so an SSID
#     containing either would be double-escaped and scan wrong.
#   * Enterprise networks (EAP / 802.1x) cannot be expressed as a password QR
#     at all, so they are refused rather than silently producing a code that
#     fails to join.
#   * NetworkManager models WEP as key-mgmt "none" plus a wep-key rather than
#     as its own key management, so a naive read sees "no security" and emits
#     an open-network QR that silently fails.
_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      let
        network-qr = pkgs.writeShellApplication {
          name = "network-qr";
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            iproute2
            networkmanager
            qrencode
          ];
          text = ''
            interface="''${1:-}"

            if [ -z "$interface" ]; then
              # Prefer whatever carries the default route, since that is the
              # connection the user means by "the Wi-Fi". Fall back to the
              # first connected wireless device.
              route_device=$(ip route get 1.1.1.1 2>/dev/null \
                | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')

              if [ -n "$route_device" ] && [ -d "/sys/class/net/$route_device/wireless" ]; then
                interface="$route_device"
              else
                interface=$(LC_ALL=C nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
                  | awk -F: '$2 == "wifi" && $3 ~ /^connected/ { print $1; exit }')
              fi
            fi

            if [ -z "$interface" ]; then
              echo "No active Wi-Fi connection" >&2
              exit 1
            fi

            uuid=$(nmcli --get-values GENERAL.CON-UUID device show "$interface" | head -n1)
            if [ -z "$uuid" ] || [ "$uuid" = "--" ]; then
              echo "No active connection on $interface" >&2
              exit 1
            fi

            mapfile -t fields < <(nmcli --show-secrets --escape no --get-values \
              802-11-wireless.ssid,802-11-wireless-security.key-mgmt,802-11-wireless-security.psk,802-11-wireless.hidden,802-11-wireless-security.wep-key0 \
              connection show uuid "$uuid")

            ssid="''${fields[0]:-}"
            key_management="''${fields[1]:-}"
            password="''${fields[2]:-}"
            hidden="''${fields[3]:-no}"
            wep_key="''${fields[4]:-}"

            if [ -z "$ssid" ]; then
              echo "Could not read the network name" >&2
              exit 1
            fi

            case "$key_management" in
              *eap* | *ieee8021x*)
                echo "Enterprise Wi-Fi cannot be shared as a password QR code" >&2
                exit 1
                ;;
            esac

            # ";" "," ":" and "\" all terminate or escape fields in the URI.
            escape_field() {
              local value="$1"
              value="''${value//\\/\\\\}"
              value="''${value//;/\\;}"
              value="''${value//,/\\,}"
              value="''${value//:/\\:}"
              printf '%s' "$value"
            }

            if [ -n "$key_management" ] && [ "$key_management" != "none" ]; then
              if [ -z "$password" ]; then
                echo "Could not read the password for $ssid" >&2
                exit 1
              fi
              security=WPA
            elif [ -n "$wep_key" ]; then
              password="$wep_key"
              security=WEP
            else
              password=""
              security=nopass
            fi

            payload="WIFI:T:$security;S:$(escape_field "$ssid");P:$(escape_field "$password");"
            [ "$hidden" = "yes" ] && payload="''${payload}H:true;"
            payload="''${payload};"

            printf '\n  %s\n' "$ssid"
            if [ "$security" = "nopass" ]; then
              printf '  open network\n\n'
            else
              printf '  %s\n\n' "$password"
            fi

            # Margin 4 is the quiet zone the spec asks for; without it a
            # scanner sitting against a dark terminal background often fails.
            qrencode -t ANSIUTF8 --margin 4 -- "$payload"

            # Launched from the waybar menu this owns its own terminal window,
            # which would close the instant the QR was drawn.
            if [ -t 0 ] && [ -t 1 ]; then
              printf '\n  Press any key to close…'
              read -r -s -n1
              printf '\n'
            fi
          '';
        };
      in
      {
        home.packages = [ network-qr ];
      }
    )
  ];
}

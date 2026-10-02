# Share active Wi-Fi as a QR code (waybar menu or terminal).
# Handles LC_ALL pinning, --escape no, EAP refusal, and WEP key-mgmt.
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
              # Prefer the default-route device; fall back to first connected wifi.
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

            # ";" "," ":" and "\" terminate or escape fields in the URI.
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

            # Margin 4 is the spec quiet zone; scanners fail without it.
            qrencode -t ANSIUTF8 --margin 4 -- "$payload"

            # Own terminal window would close instantly; wait for a keypress.
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

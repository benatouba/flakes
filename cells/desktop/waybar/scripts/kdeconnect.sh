#!/usr/bin/env bash
# State line for waybar's custom/phone module.
#
# kdeconnect-cli has no --battery flag, so reachability comes from
# `kdeconnect-cli -a --id-only` and charge/charging state from the
# kdeconnectd D-Bus API via busctl (systemd, always present — no qdbus
# dependency):
#   /modules/kdeconnect/devices/<id>         org.kde.kdeconnect.device (name)
#   /modules/kdeconnect/devices/<id>/battery org.kde.kdeconnect.device.battery
#                                             (charge, isCharging)
#
# Click actions live in the waybar config, not here:
#   left = kdeconnect-app, middle = ring, right = send clipboard.
set -euo pipefail

disconnected() {
  printf '{"text":"󰄜","class":"disconnected","tooltip":"Phone disconnected"}\n'
}

ids=$(kdeconnect-cli -a --id-only 2>/dev/null | sed '/^[[:space:]]*$/d' || true)
if [[ -z $ids ]]; then
  disconnected
  exit 0
fi

id=$(printf '%s\n' "$ids" | head -n1)
count=$(printf '%s\n' "$ids" | wc -l)

name=$(busctl --user get-property org.kde.kdeconnect \
  "/modules/kdeconnect/devices/$id" org.kde.kdeconnect.device name 2>/dev/null \
  | sed 's/^s "\(.*\)"$/\1/' || true)
if [[ -z ${name:-} ]]; then
  disconnected
  exit 0
fi
[[ $count -gt 1 ]] && name="$name (+$((count - 1)) more)"

charge=$(busctl --user get-property org.kde.kdeconnect \
  "/modules/kdeconnect/devices/$id/battery" \
  org.kde.kdeconnect.device.battery charge 2>/dev/null | awk '{print $2}' || true)
charging=$(busctl --user get-property org.kde.kdeconnect \
  "/modules/kdeconnect/devices/$id/battery" \
  org.kde.kdeconnect.device.battery isCharging 2>/dev/null | awk '{print $2}' || true)

# Battery plugin disabled/unavailable on the phone: show presence only.
if [[ -z ${charge:-} ]]; then
  printf '{"text":"󰄜","class":"connected","tooltip":"%s\\nLeft: open · Middle: ring · Right: clipboard"}\n' "$name"
  exit 0
fi

# Same 10-step Nerd Font ramp as the laptop battery module.
icons=("󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
idx=$((charge / 10))
((idx < 0)) && idx=0
((idx > 9)) && idx=9
icon=${icons[$idx]}

class="connected"
state="discharging"
if [[ $charging == "true" ]]; then
  class="charging"
  state="charging"
elif ((charge <= 15)); then
  class="critical"
elif ((charge <= 30)); then
  class="warning"
fi

if [[ $charging == "true" ]]; then
  text="$icon $charge% 󰂄"
else
  text="$icon $charge%"
fi

printf '{"text":"%s","class":"%s","percentage":%d,"tooltip":"%s — %d%% (%s)\\nLeft: open · Middle: ring · Right: clipboard"}\n' \
  "$text" "$class" "$charge" "$name" "$charge" "$state"

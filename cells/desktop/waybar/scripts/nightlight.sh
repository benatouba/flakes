#!/usr/bin/env bash
# State line for waybar's custom/nightlight module.
#
# hyprsunset has no query interface — `hyprctl hyprsunset` only issues requests —
# so the temperature the bar last set is remembered in a runtime file. It lives
# in XDG_RUNTIME_DIR rather than the home directory because it describes the
# running compositor: both are gone at logout, and hyprland/autostart.conf
# starts hyprsunset at 5200 K again on the next login.
#
# An absent file therefore means "whatever autostart set", which is 5200 K, not
# "off". Only the menu's Off entry writes the literal `off`.
set -euo pipefail

state="${XDG_RUNTIME_DIR:-/tmp}/waybar-nightlight"
autostart_temperature=5200

if [[ -s $state ]]; then
  temperature=$(<"$state")
else
  temperature=$autostart_temperature
fi

if [[ $temperature == "off" ]]; then
  printf '{"text":"󰔎","class":"off","tooltip":"Night light off"}\n'
else
  printf '{"text":"󰔎","class":"on","tooltip":"Night light on — %s K"}\n' "$temperature"
fi

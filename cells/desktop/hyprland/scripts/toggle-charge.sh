#!/usr/bin/env bash
# Toggle battery charging on/off
STATE_FILE="/tmp/tlp-chargeonce-active"

if [ -f "$STATE_FILE" ]; then
    pkexec tlp setcharge 20 80 BAT0
    rm "$STATE_FILE"
    notify-send "Battery" "Charging stopped, thresholds restored (20/80)"
else
    pkexec tlp chargeonce BAT0
    touch "$STATE_FILE"
    notify-send "Battery" "Charging to 80%"
fi

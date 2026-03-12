#!/usr/bin/env bash

enable_battery=false
battery_charging=false

for battery in /sys/class/power_supply/*BAT*; do
  if [[ -f "$battery/uevent" ]]; then
    enable_battery=true
    if [[ $(cat /sys/class/power_supply/*/status | head -1) == "Charging" ]]; then
      battery_charging=true
    fi
    break
  fi
done

if [[ $enable_battery == true ]]; then
  if [[ $battery_charging == true ]]; then
    echo -n "(+) "
  fi
  echo -n "$(cat /sys/class/power_supply/*/capacity | head -1)%"
  if [[ $battery_charging == false ]]; then
    echo -n " remaining"
  fi
fi

echo ''

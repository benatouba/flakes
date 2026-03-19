#!/usr/bin/env bash
# Power management script for wlogout/keybinds

if [[ "$1" == "exit" ]]; then
    hyprctl dispatch exit
fi

if [[ "$1" == "lock" ]]; then
    hyprlock
fi

if [[ "$1" == "reboot" ]]; then
    systemctl reboot
fi

if [[ "$1" == "shutdown" ]]; then
    systemctl poweroff
fi

if [[ "$1" == "suspend" ]]; then
    systemctl suspend
fi

if [[ "$1" == "hibernate" ]]; then
    systemctl hibernate
fi

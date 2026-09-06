#!/usr/bin/env bash
# Restart the session components after a Hyprland reload.
#
# This used to pkill each process and sleep a guessed interval before starting
# it again — 0.4s for waybar, 0.1s for xsettingsd, 0.2s for hypridle. The one
# component that had a *correct* wait (a `while pgrep` loop for swaync) was
# commented out, which says how well the sleeps worked.
#
# systemd serialises stop-then-start within a unit, so none of that is needed:
# restart returns when the unit is actually up, and a failure is visible in
# `systemctl --user status` rather than silently leaving a gap on the bar.
set -euo pipefail

systemctl --user restart waybar.service xsettingsd.service hypridle.service swaync.service

# Not a restart: hyprpaper keeps running, this just asks it for a new image.
systemctl --user start random-wallpaper.service

#!/usr/bin/env bash
dir="$HOME/.config/rofi"
theme="$dir/config.rasi"
rofi -no-lazy-grab -show drun -modi "drun,filebrowser,window,run" -theme "$theme"

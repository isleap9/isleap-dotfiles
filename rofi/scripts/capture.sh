#!/bin/bash

ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
SCREENSHOTS="$HOME/Pictures/Screenshots"

CHOICE=$(printf '%s\n' \
    "󰹑  Region" \
    "󰍹  Fullscreen" \
    "󱣴  Window" \
    | rofi -dmenu \
        -p "Capture" \
        -i \
        -no-custom \
        -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

notify-send "Debug" "Choice: $CHOICE"

case "$CHOICE" in
    *"Region")     sleep 0.2; hyprshot -m region --output-folder "$SCREENSHOTS" ;;
    *"Fullscreen") sleep 0.2; hyprshot -m output -m active --output-folder "$SCREENSHOTS" ;;
	*"Window") sleep 0.2; hyprshot -m window --output-folder "$SCREENSHOTS" ;;
esac

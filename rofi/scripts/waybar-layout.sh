#!/bin/bash

ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
WAYBAR_CONFIGS="$HOME/.config/waybar/configs"
WAYBAR_STYLES="$HOME/.config/waybar/styles"
LAYOUT_FILE="$HOME/.config/waybar/current-layout"

CHOICE=$(printf '%s\n' \
    "  Default" \
    "  Default 2" \
    "  Minimal" \
    | rofi -dmenu \
        -p "Waybar Layout" \
        -i \
        -no-custom \
        -theme "$ROFI_THEME")

case "$CHOICE" in
    *"Default")   echo "default"  > "$LAYOUT_FILE" ;;
    *"Default 2") echo "default2" > "$LAYOUT_FILE" ;;
    *"Minimal")   echo "minimal"  > "$LAYOUT_FILE" ;;
esac

LAYOUT=$(cat "$LAYOUT_FILE")
pkill waybar
waybar --config "$WAYBAR_CONFIGS/${LAYOUT}.jsonc" --style "$WAYBAR_STYLES/${LAYOUT}.css" &disown

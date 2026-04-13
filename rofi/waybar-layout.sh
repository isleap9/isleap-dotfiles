#!/bin/bash
# ~/.config/rofi/scripts/waybar-layout.sh

ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
WAYBAR_CONFIGS="$HOME/.config/waybar/configs"
WAYBAR_STYLES="$HOME/.config/waybar/styles"

CHOICE=$(printf '%s\n' \
    "  Default" \
    "  Minimal" \
    | rofi -dmenu \
        -p "Waybar Layout" \
        -i \
        -no-custom \
        -theme "$ROFI_THEME")  # ← )

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *"Default") pkill waybar; waybar --config "$WAYBAR_CONFIGS/default.jsonc" --style "$WAYBAR_STYLES/default.css" &disown ;;
    *"Minimal")  pkill waybar; waybar --config "$WAYBAR_CONFIGS/minimal.jsonc"  --style "$WAYBAR_STYLES/minimal.css"  &disown ;;
esac

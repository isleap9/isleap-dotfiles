#!/bin/bash

ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
WAYBAR_CONFIGS="$HOME/.config/waybar/configs"
WAYBAR_STYLES="$HOME/.config/waybar/styles"
LAYOUT_FILE="$HOME/.config/waybar/current-layout"

CHOICE=$(printf '%s\n' \
	"󰁍  Back" \
    "  Default" \
    "  Default 2" \
    "  Minimal" \
    | rofi -dmenu -hover-select -me-select-entry "" -me-accept-entry "MousePrimary" \
        -p "Waybar Layout" \
        -i \
        -no-custom \
        -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
	*"Back")      bash "$HOME/.config/rofi/scripts/control-center.sh" ;;
    *"Default")   echo "default"  > "$LAYOUT_FILE" ;;
    *"Default 2") echo "default2" > "$LAYOUT_FILE" ;;
    *"Minimal")   echo "minimal"  > "$LAYOUT_FILE" ;;
esac

LAYOUT=$(cat "$LAYOUT_FILE")
pkill waybar
waybar --config "$WAYBAR_CONFIGS/${LAYOUT}.jsonc" --style "$WAYBAR_STYLES/${LAYOUT}.css" &disown

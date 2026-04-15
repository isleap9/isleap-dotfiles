#!/bin/bash

ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
LAYOUT_FILE="$HOME/.config/rofi/current-layout"

CHOICE=$(printf '%s\n' \
	"󰁍  Back" \
    "  Default" \
    "  Minimal" \
    | rofi -dmenu \
        -p "Rofi Layout" \
        -i \
        -no-custom \
        -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
	*"Back")     bash "$HOME/.config/rofi/scripts/control-center.sh" ;;
    *"Minimal")  echo "style-2" > "$LAYOUT_FILE" ;;
    *"Default") echo "type-6"  > "$LAYOUT_FILE" ;;
esac

notify-send "Rofi Layout" "Switched to $CHOICE" --icon=preferences-desktop-theme

#!/bin/bash

ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
LAYOUT_FILE="$HOME/.config/rofi/current-layout"

CHOICE=$(printf '%s\n' \
    "  Default" \
    "  Showcase" \
    | rofi -dmenu \
        -p "Rofi Layout" \
        -i \
        -no-custom \
        -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *"Default")  echo "style-2" > "$LAYOUT_FILE" ;;
    *"Showcase") echo "type-6"  > "$LAYOUT_FILE" ;;
esac

notify-send "Rofi Layout" "Switched to $CHOICE" --icon=preferences-desktop-theme

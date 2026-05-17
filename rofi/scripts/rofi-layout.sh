#!/bin/bash
ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
LAYOUT_FILE="$HOME/.config/rofi/current-layout"

CHOICE=$(printf "%s
"     "󰁍  Back"     "  Default"     "  Minimal"     "  Sleek"     | rofi -dmenu         -hover-select         -me-select-entry ""         -me-accept-entry "MousePrimary"         -p "Rofi Layout"         -i         -no-custom         -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *"Back")    bash "$HOME/.config/rofi/scripts/control-center.sh" ;;
    *"Default") echo "type-6"   > "$LAYOUT_FILE" ;;
    *"Minimal") echo "style-2"  > "$LAYOUT_FILE" ;;
    *"Sleek")   echo "style-15" > "$LAYOUT_FILE" ;;
esac

notify-send "Rofi Layout" "Switched to $CHOICE" --icon=preferences-desktop-theme

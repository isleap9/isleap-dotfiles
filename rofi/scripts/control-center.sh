#!/bin/bash

# Paths
SCRIPTS="$HOME/.config/rofi/scripts"
ROFI_THEME="$HOME/.config/rofi/control-center.rasi"

# Menu entries
MENU=$(printf '%s\n' \
    "󰀻  Waybar Layout" \
    "  Rofi Layout" \
    "󰧨  Theme Switcher" \
    "󰔎  Dynamic Theme" \
    "󰸉  Wallpaper Switcher" \
    "  Clipboard" \
    "  Capture" \
    "󰞅  Emoji" \
    "  Cheatsheet"
)

CHOICE=$(echo "$MENU" | rofi -dmenu -hover-select -me-select-entry "" -me-accept-entry "MousePrimary" \
    -p "Select Option" \
    -i \
    -no-custom \
    -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *"Waybar Layout")      bash "$SCRIPTS/waybar-layout.sh" ;;
    *"Rofi Layout")        bash "$SCRIPTS/rofi-layout.sh" ;;
    *"Theme Switcher")     bash "$HOME/.config/waybar/scripts/theme-switcher.sh" ;;
    *"Dynamic Theme")      bash "$HOME/.config/rofi/scripts/dynamic-theme-menu.sh" ;;
    *"Wallpaper Switcher") bash "$SCRIPTS/wallpaper-picker.sh" ;;
    *"Clipboard")          bash "$SCRIPTS/clipboard.sh" ;;
    *"Capture")            bash "$SCRIPTS/capture.sh" ;;
    *"Emoji")              bash "$SCRIPTS/emoji.sh" ;;
    *"Cheatsheet")         bash "$SCRIPTS/cheatsheet.sh" ;;
esac

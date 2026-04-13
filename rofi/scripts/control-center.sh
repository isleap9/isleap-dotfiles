#!/bin/bash

# Paths
SCRIPTS="$HOME/.config/rofi/scripts"
ROFI_THEME="$HOME/.config/rofi/control-center.rasi"

# Menu entries
MENU=$(printf '%s\n' \
    "󰀻  Waybar Layout" \
    "  Rofi Layout" \
    "󰧨  Theme Switcher" \
    "󰸉  Wallpaper Switcher" \
    "  Clipboard" \
    "  Capture" \
    "󰞅  Emoji" \
    "  Cheatsheet"
)

CHOICE=$(echo "$MENU" | rofi -dmenu \
    -p "Select Option" \
    -i \
    -no-custom \
    -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *"Waybar Layout")      bash "$SCRIPTS/waybar-layout.sh" ;;
    *"Rofi Layout")        bash "$SCRIPTS/rofi-layout.sh" ;;
    *"Theme Switcher")     bash "$HOME/.config/waybar/scripts/theme-switcher.sh" ;;
    *"Wallpaper Switcher") bash "$SCRIPTS/wallpaper-picker.sh" ;;
    *"Clipboard")          cliphist list | rofi -dmenu -display-columns 2 -p "Clipboard" -theme "$ROFI_THEME" | cliphist decode | wl-copy ;;
    *"Capture")            bash "$SCRIPTS/capture.sh" ;;
    *"Emoji")              bash "$SCRIPTS/emoji.sh" ;;
    *"Cheatsheet")         bash "$SCRIPTS/cheatsheet.sh" ;;
esac
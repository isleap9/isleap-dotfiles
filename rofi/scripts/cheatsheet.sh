#!/bin/bash

ROFI_THEME="$HOME/.config/rofi/cheatsheet.rasi"

BINDS=$(printf '%s\n' \
    "󰁍  Back" \
    "  SUPER + T           Terminal" \
    "󰅙  SUPER + Q           Kill Window" \
    "󰖟  SUPER + B           Browser" \
    "󰨞  SUPER + C           VSCode" \
    "󰍃  SUPER + M           Logout" \
    "󰉋  SUPER + E           Files" \
    "󰉯  SUPER + W           Toggle Float" \
    "󰀻  SUPER + A           App Launcher" \
    "󰍹  SUPER + F           Fullscreen" \
    "󰖲  SUPER + S           Scratchpad" \
    "󰍹  SUPER + N           Notifications" \
    "󰌌  SUPER + L           Lock Screen" \
    "󰸉  SUPER + SHIFT + W   Wallpaper" \
    "󰹉  SUPER + SHIFT + T   Theme Switcher" \
    "  SUPER + SHIFT + E   Control Center" \
    "󰃣 SUPER + SHIFT + P   Color picker" \
    "󰹑  SUPER + SHIFT + S   Screenshot Region" \
    "󰍜  SUPER + SHIFT + V   Capture Menu" \
    "  SUPER + SHIFT + C   Clipboard" \
    "󰒅  SUPER + R           Reload Waybar" \
    "󰒭  SUPER + j/l/i/k     Move Focus" \
    "󰒭  SUPER + 1-0         Switch Workspace" \
    "󰒭  SUPER + SHIFT 1-0   Move to Workspace" \
)

CHOICE=$(echo "$BINDS" | rofi -dmenu -hover-select -me-select-entry "" -me-accept-entry "MousePrimary" \
    -p "Keybinds" \
    -i \
    -no-custom \
    -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

if [[ "$CHOICE" == *"Back"* ]]; then
    bash "$HOME/.config/rofi/scripts/control-center.sh"
fi

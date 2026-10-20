#!/usr/bin/env bash
# Set an image as wallpaper (used by Dolphin's right-click "Set as Wallpaper").
# If dynamic theme mode is on, also regenerate colors from it.
WALL="$1"
[[ -f "$WALL" ]] || { notify-send "Wallpaper" "File not found: $WALL" --icon=dialog-error; exit 1; }

awww img "$WALL" --transition-type fade --transition-duration 2 --transition-fps 60

if [[ -f "$HOME/.cache/dynamic-theme-enabled" ]]; then
    SKIP_WALLPAPER=1 "$HOME/.config/hypr/scripts/wallpaper-dynamic.sh" "$WALL"
fi

#!/bin/bash

# Get current wallpaper from awww
WALLPAPER=$(awww query | grep -o 'image: .*' | head -1)
WALLPAPER=${WALLPAPER#image: }

# Only update symlink if wallpaper path is valid
if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    CURRENT=$(readlink ~/.config/rofi/images/a.png 2>/dev/null)
    if [ "$CURRENT" != "$WALLPAPER" ]; then
        ln -sf "$WALLPAPER" ~/.config/rofi/images/a.png
    fi
fi

# Get current layout, fallback to style-2
LAYOUT_FILE="$HOME/.config/rofi/current-layout"
LAYOUT=$(cat "$LAYOUT_FILE" 2>/dev/null || echo "style-2")

# Fallback if layout file doesn't exist on disk
if [ ! -f "$HOME/.config/rofi/${LAYOUT}.rasi" ]; then
    LAYOUT="style-2"
fi

rofi -show drun \
    -hover-select \
    -me-select-entry "" \
    -me-accept-entry "MousePrimary" \
    -theme "$HOME/.config/rofi/${LAYOUT}.rasi"

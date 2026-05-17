#!/bin/bash

WALLPAPER=$(awww query | grep -o 'image: .*' | head -1)
WALLPAPER=${WALLPAPER#image: }

ln -sf "$WALLPAPER" ~/.config/rofi/images/a.png

LAYOUT_FILE="$HOME/.config/rofi/current-layout"
LAYOUT=$(cat "$LAYOUT_FILE" 2>/dev/null || echo "style-2")

rofi -show drun -hover-select -me-select-entry "" -me-accept-entry "MousePrimary" -theme "$HOME/.config/rofi/${LAYOUT}.rasi"

#!/bin/bash

WALLPAPER=$(awww query | awk -F'image: ' '{print $2}' | head -1)
mkdir -p ~/.config/rofi/images
ln -sf "$WALLPAPER" ~/.config/rofi/images/a.png

LAYOUT_FILE="$HOME/.config/rofi/current-layout"
LAYOUT=$(cat "$LAYOUT_FILE" 2>/dev/null || echo "style-2")

rofi -show drun -theme "$HOME/.config/rofi/${LAYOUT}.rasi"

#!/usr/bin/env bash

LAYOUT=$(cat "$HOME/.config/waybar/current-layout" 2>/dev/null || echo "default")

pkill waybar
pkill swaync
waybar --config "$HOME/.config/waybar/configs/${LAYOUT}.jsonc" --style "$HOME/.config/waybar/styles/${LAYOUT}.css" &
swaync &
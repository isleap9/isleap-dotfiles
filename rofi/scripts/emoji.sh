#!/bin/bash
ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
BACK="← Back"

CHOICE=$(rofimoji --action copy --skin-tone neutral --selector-args "-theme $HOME/.config/rofi/control-center.rasi -p Emoji")
[ -z "$CHOICE" ] && bash "$HOME/.config/rofi/scripts/control-center.sh" && exit 0

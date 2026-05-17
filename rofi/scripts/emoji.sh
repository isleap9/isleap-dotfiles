#!/bin/bash
ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
BACK="← Back"
ARGS="-theme $HOME/.config/rofi/control-center.rasi -p Emoji -hover-select -me-select-entry '' -me-accept-entry 'MousePrimary'"
CHOICE=$(rofimoji --action copy --skin-tone neutral --selector-args "$ARGS")
[ -z "$CHOICE" ] && bash "$HOME/.config/rofi/scripts/control-center.sh" && exit 0

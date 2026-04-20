#!/bin/bash
ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
STATE_FILE="$HOME/.cache/dynamic-theme-enabled"
SCHEME_FILE="$HOME/.cache/matugen-scheme"
MODE_FILE="$HOME/.cache/matugen-mode"

if [[ -f "$STATE_FILE" ]]; then
    STATUS="● Dynamic Theme: ON"
    TOGGLE="○  Turn OFF Dynamic Theme"
else
    STATUS="○ Dynamic Theme: OFF"
    TOGGLE="●  Turn ON Dynamic Theme"
fi

CURRENT_SCHEME=$(cat "$SCHEME_FILE" 2>/dev/null | tr -d '[:space:]')
[[ -z "$CURRENT_SCHEME" ]] && CURRENT_SCHEME="scheme-tonal-spot"

CURRENT_MODE=$(cat "$MODE_FILE" 2>/dev/null | tr -d '[:space:]')
[[ -z "$CURRENT_MODE" ]] && CURRENT_MODE="dark"

if [[ "$CURRENT_MODE" == "dark" ]]; then
    MODE_LABEL="󰖨  Mode  [dark] → switch to light"
else
    MODE_LABEL="󰖨  Mode  [light] → switch to dark"
fi

MENU=$(printf '%s\n' \
    "󰁍  Back to Control Center" \
    "$TOGGLE" \
    "󰔎  Apply to Current Wallpaper" \
    "󰸀  Scheme Type  [$CURRENT_SCHEME]" \
    "$MODE_LABEL"
)

CHOICE=$(echo "$MENU" | rofi -dmenu \
    -p "$STATUS" \
    -i \
    -no-custom \
    -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *"Back to Control Center")
        bash "$HOME/.config/rofi/scripts/control-center.sh"
        ;;
    *"Turn ON"*)
        touch "$STATE_FILE"
        notify-send "Dynamic Theme" "Enabled — pick a wallpaper to apply" --icon=preferences-desktop-theme --hint=int:transient:1
        ;;
    *"Turn OFF"*)
        rm -f "$STATE_FILE"
        notify-send "Dynamic Theme" "Disabled" --icon=preferences-desktop-theme --hint=int:transient:1
        ;;
    *"Apply to Current Wallpaper"*)
        if [[ ! -f "$STATE_FILE" ]]; then
            notify-send "Dynamic Theme" "Enable dynamic theme first" --icon=dialog-warning --hint=int:transient:1
            exit 0
        fi
        CURRENT=$(sed 's|^[^/]*||' ~/.cache/awww/0.12.0/DP-3 2>/dev/null | tr -d '\n')
        if [[ -f "$CURRENT" ]]; then
            ~/.config/hypr/scripts/wallpaper-dynamic.sh "$CURRENT"
        else
            notify-send "Dynamic Theme" "No wallpaper found" --icon=dialog-warning
        fi
        ;;
    *"Scheme Type"*)
        bash "$HOME/.config/rofi/scripts/matugen-scheme.sh"
        ;;
    *"Mode"*)
        CURRENT_MODE=$(cat "$MODE_FILE" 2>/dev/null | tr -d '[:space:]')
        [[ -z "$CURRENT_MODE" ]] && CURRENT_MODE="dark"
        if [[ "$CURRENT_MODE" == "dark" ]]; then
            echo "light" > "$MODE_FILE"
            notify-send "Dynamic Theme" "Mode: Light" --icon=weather-clear --hint=int:transient:1
        else
            echo "dark" > "$MODE_FILE"
            notify-send "Dynamic Theme" "Mode: Dark" --icon=weather-clear-night --hint=int:transient:1
        fi
        CURRENT=$(sed 's|^[^/]*||' ~/.cache/awww/0.12.0/DP-3 2>/dev/null | tr -d '\n')
        if [[ -f "$CURRENT" ]]; then
            ~/.config/hypr/scripts/wallpaper-dynamic.sh "$CURRENT"
        fi
        ;;
esac

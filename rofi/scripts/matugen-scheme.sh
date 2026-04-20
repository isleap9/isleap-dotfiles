#!/bin/bash
SCHEMES=$(printf '%s
' \
    "󰁍  Back to Dynamic Menu" \
    "scheme-tonal-spot  (default)" \
    "scheme-vibrant     (punchy)" \
    "scheme-expressive  (colorful)" \
    "scheme-fidelity    (wallpaper-close)" \
    "scheme-content     (content-aware)" \
    "scheme-neutral     (muted)" \
    "scheme-monochrome  (grayscale)" \
    "scheme-rainbow     (multi-hue)" \
    "scheme-fruit-salad (playful)"
)

CHOICE=$(echo "$SCHEMES" | rofi -dmenu \
    -p "Scheme Type" \
    -i \
    -no-custom \
    -theme "$HOME/.config/rofi/scheme-picker.rasi")

[ -z "$CHOICE" ] && exit 0

if [[ "$CHOICE" == *"Back"* ]]; then
    bash "$HOME/.config/rofi/scripts/dynamic-theme-menu.sh"
    exit 0
fi

SCHEME=$(echo "$CHOICE" | awk '{print $1}')
echo "$SCHEME" > ~/.cache/matugen-scheme

CURRENT=$(sed 's|^[^/]*||' ~/.cache/awww/0.12.0/DP-3 2>/dev/null | tr -d '
')
if [[ -f "$CURRENT" ]]; then
    ~/.config/hypr/scripts/wallpaper-dynamic.sh "$CURRENT"
fi

notify-send "Dynamic Theme" "Scheme: $SCHEME" --icon=preferences-desktop-theme --hint=int:transient:1

#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="${1:-}"
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Usage: wallpaper-dynamic.sh <path-to-image>" >&2
    exit 1
fi

WAYBAR_THEMES="$HOME/.config/waybar/themes"
KITTY_THEMES="$HOME/.config/kitty/themes"
SWAYNC_THEMES="$HOME/.config/swaync/themes-colors"
WLOGOUT_THEMES="$HOME/.config/wlogout/themes"
HYPR_THEMES="$HOME/.config/hypr/modules/themes"
ROFI_COLORS="$HOME/.config/rofi/colors"
HYPR_DYNAMIC="$HYPR_THEMES/dynamic.lua"
WAYBAR_LAYOUT_FILE="$HOME/.config/waybar/current-layout"

awww img "$WALLPAPER" --transition-type fade --transition-duration 2 --transition-fps 60

SCHEME=$(cat ~/.cache/matugen-scheme 2>/dev/null || echo "scheme-tonal-spot")
MODE=$(cat ~/.cache/matugen-mode 2>/dev/null || echo "dark")
matugen -c ~/.config/matugen/config.toml image "$WALLPAPER" --type "$SCHEME" -m "$MODE" --source-color-index 0

ln -sf "$WAYBAR_THEMES/dynamic.css"  "$WAYBAR_THEMES/active.css"
ln -sf "$KITTY_THEMES/dynamic.conf"  "$KITTY_THEMES/active.conf"
ln -sf "$SWAYNC_THEMES/dynamic.css"  "$SWAYNC_THEMES/active.css"
ln -sf "$WLOGOUT_THEMES/dynamic.css" "$HOME/.config/wlogout/style.css"
ln -sf "$HYPR_THEMES/dynamic.lua"   "$HOME/.config/hypr/modules/active.lua"
ln -sf "$ROFI_COLORS/dynamic.rasi"   "$ROFI_COLORS/active.rasi"



PRIMARY_HEX=$(grep "col.active_border" "$HYPR_DYNAMIC" | grep -oP "[A-Fa-f0-9]{6}" | head -1 || echo "ffffff")
PRIMARY_COLOR="#${PRIMARY_HEX}"
ONSURFACE_HEX=$(grep "define-color fg1" "$WAYBAR_THEMES/dynamic.css" | grep -oP "#[A-Fa-f0-9]{6}")

for CONFIG in "$HOME/.config/waybar/configs/default.jsonc" "$HOME/.config/waybar/configs/default2.jsonc"; do
    [[ -f "$CONFIG" ]] || continue
    sed -i "s|months.*<span color=.\([^\.]*\).>|months": "<span color='${PRIMARY_COLOR}'>|g" "$CONFIG" || true
    sed -i "s|days.*<span color=.\([^\.]*\).>|days": "<span color='${ONSURFACE_HEX}'>|g" "$CONFIG" || true
done

LAYOUT=$(cat "$WAYBAR_LAYOUT_FILE" 2>/dev/null || echo "default")
hyprctl reload 2>/dev/null || true
pkill -9 waybar || true
sleep 0.2
waybar --config "$HOME/.config/waybar/configs/${LAYOUT}.jsonc" --style "$HOME/.config/waybar/styles/${LAYOUT}.css" &disown

pkill -USR1 kitty 2>/dev/null || true
swaync-client --reload-css &disown

python3 -c "
import re, os
path = os.path.expanduser('~/.local/share/color-schemes/Dynamic.colors')
content = open(path).read()
content = re.sub(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)', r'\1,\2,\3', content)
open(path, 'w').write(content)
"

# Force plasma to reload even if scheme name is the same
plasma-apply-colorscheme BreezeLight 2>/dev/null || true
sleep 0.2
plasma-apply-colorscheme Dynamic
qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

notify-send "Dynamic Theme" "Colors from $(basename "$WALLPAPER")" --icon=preferences-desktop-theme --hint=int:transient:1

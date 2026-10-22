#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="${1:-}"
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Usage: wallpaper-dynamic.sh <path-to-image>" >&2
    exit 1
fi

WAYBAR_THEMES="$HOME/.config/waybar/themes"
KITTY_THEMES="$HOME/.config/kitty/themes"
HYPR_THEMES="$HOME/.config/hypr/modules/themes"

[[ "${SKIP_WALLPAPER:-0}" == 1 ]] || awww img "$WALLPAPER" --transition-type fade --transition-duration 2 --transition-fps 60

SCHEME=$(cat ~/.cache/matugen-scheme 2>/dev/null || echo "scheme-tonal-spot")
MODE=$(cat ~/.cache/matugen-mode 2>/dev/null || echo "dark")
matugen -c ~/.config/matugen/config.toml image "$WALLPAPER" --type "$SCHEME" -m "$MODE" --source-color-index 0

ln -sf "$WAYBAR_THEMES/dynamic.css"  "$WAYBAR_THEMES/active.css"
ln -sf "$KITTY_THEMES/dynamic.conf"  "$KITTY_THEMES/active.conf"
ln -sf "$HYPR_THEMES/dynamic.lua"   "$HOME/.config/hypr/modules/active.lua"

hyprctl reload 2>/dev/null || true
# Recolor Quickshell
qs ipc call theme reload >/dev/null 2>&1 &disown

pkill -USR1 kitty 2>/dev/null || true

cp ~/.config/btop/themes/dynamic.theme ~/.config/btop/themes/active.theme
pkill -SIGUSR2 btop 2>/dev/null || true

python3 -c "
import re, os
path = os.path.expanduser('~/.local/share/color-schemes/Dynamic.colors')
content = open(path).read()
content = re.sub(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)', r'\1,\2,\3', content)
open(path, 'w').write(content)
"

# Apply KDE colors (Dolphin etc.) without Plasma
"$HOME/.config/hypr/scripts/apply-kde-colors.sh" Dynamic


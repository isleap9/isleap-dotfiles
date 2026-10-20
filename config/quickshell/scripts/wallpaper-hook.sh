#!/usr/bin/env bash
# Called by qs-wallpaper-picker after a wallpaper is applied ($WALL = image path).
# When dynamic theme mode is on, regenerate colors from the new wallpaper.
[[ -f "$HOME/.cache/dynamic-theme-enabled" ]] || exit 0
[[ -n "${WALL:-}" && -f "$WALL" ]] || exit 0
SKIP_WALLPAPER=1 exec "$HOME/.config/hypr/scripts/wallpaper-dynamic.sh" "$WALL"

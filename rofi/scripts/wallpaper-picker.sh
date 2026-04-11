#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/rofi-wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"

mkdir -p "$CACHE_DIR"

declare -a names

# Build entries array and generate thumbnails
for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,gif,webp}; do
    [ -f "$img" ] || continue
    name=$(basename "$img")
    thumb="$CACHE_DIR/$name"
    if [ ! -f "$thumb" ]; then
        ffmpegthumbnailer -i "$img" -o "$thumb" -s 256 -q 10
    fi
    names+=("$name")
done

# Write entries to temp file with proper separators
TMPFILE=$(mktemp)

# Random option first
printf "🎲 Random Wallpaper\0icon\x1f%s/%s\n" "$CACHE_DIR" "${names[0]}" >> "$TMPFILE"

# All wallpapers
for i in "${!names[@]}"; do
    printf "%s\0icon\x1f%s/%s\n" "${names[$i]}" "$CACHE_DIR" "${names[$i]}" >> "$TMPFILE"
done

# Show rofi
chosen=$(rofi -dmenu -i \
    -p "Select Wallpaper" \
    -show-icons \
    -icon-size 160 \
    -format s \
    -config "$ROFI_THEME" < "$TMPFILE")

rm -f "$TMPFILE"

[ -z "$chosen" ] && exit 0

# Handle random
if [ "$chosen" = "🎲 Random Wallpaper" ]; then
    chosen="${names[$RANDOM % ${#names[@]}]}"
fi

# Set wallpaper
awww img "$WALLPAPER_DIR/$chosen" \
    --transition-type fade \
    --transition-duration 2 \
    --transition-fps 60
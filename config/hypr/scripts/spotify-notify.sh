#!/bin/bash
# Shows a notification with the cover art when the Spotify song changes.
# Spotify often reports the same song more than once (e.g. before and after the cover
# loads), so a song that was just announced is skipped.

CACHE_DIR="/tmp/spotify-art"
mkdir -p "$CACHE_DIR"
last=""

playerctl --player=spotify --follow metadata --format '{{title}}|{{artist}}|{{mpris:artUrl}}' | \
while IFS='|' read -r title artist arturl; do
    [[ -z "$title" ]] && continue
    [[ "$title|$artist" == "$last" ]] && continue
    last="$title|$artist"

    # One file per cover: popups cache images by file name, so reusing one name shows old covers
    CACHE_FILE="$CACHE_DIR/$(basename "$arturl").jpg"
    find "$CACHE_DIR" -type f -mmin +120 -delete 2>/dev/null

    if [[ -n "$arturl" ]]; then
        curl -s -o "$CACHE_FILE" "$arturl"
        notify-send -i "$CACHE_FILE" -a "Spotify" "$title" "$artist" -t 3000
    else
        notify-send -a "Spotify" "$title" "$artist" -t 3000
    fi
done

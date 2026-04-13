#!/bin/bash

CACHE_DIR="/tmp/spotify-art"
mkdir -p "$CACHE_DIR"

playerctl --player=spotify --follow metadata --format '{{title}}|{{artist}}|{{mpris:artUrl}}' | \
while IFS='|' read -r title artist arturl; do
    [[ -z "$title" ]] && continue

    CACHE_FILE="$CACHE_DIR/cover.jpg"

    if [[ -n "$arturl" ]]; then
        curl -s -o "$CACHE_FILE" "$arturl"
        notify-send -i "$CACHE_FILE" -a "Spotify" "$title" "$artist" -t 3000
    else
        notify-send -a "Spotify" "$title" "$artist" -t 3000
    fi
done

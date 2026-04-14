#!/bin/bash

ROFI_THEME="$HOME/.config/rofi/control-center.rasi"
FAVORITES="$HOME/.config/cliphist/favorites"

BACK="󰁍  Back"
ADD_FAV="󰣐  Add to Favorites"
REMOVE_FAV="󰛌  Remove Favorite"
VIEW_FAV="󰋃  Favorites"
VIEW_ALL="󰅍  All Clips"

ACTION=$(printf '%s\n' \
    "$BACK" \
    "$VIEW_FAV" \
    "$VIEW_ALL" \
    "$ADD_FAV" \
    "$REMOVE_FAV" \
    | rofi -dmenu \
        -p "Clipboard" \
        -i \
        -no-custom \
        -theme "$ROFI_THEME")

[ -z "$ACTION" ] && exit 0

case "$ACTION" in
    "$BACK")
        bash "$HOME/.config/rofi/scripts/control-center.sh" ;;
    "$VIEW_FAV")
        if [ ! -s "$FAVORITES" ]; then
            notify-send "Clipboard" "No favorites yet" --icon=dialog-information
            exit 0
        fi
        CHOICE=$(cat "$FAVORITES" | rofi -dmenu \
            -p "Favorites" \
            -i \
            -theme "$ROFI_THEME")
        [ -z "$CHOICE" ] && exit 0
        echo -n "$CHOICE" | wl-copy
        ;;
    "$VIEW_ALL")
        CHOICE=$(cliphist list | rofi -dmenu \
            -display-columns 2 \
            -p "Clipboard" \
            -i \
            -theme "$ROFI_THEME")
        [ -z "$CHOICE" ] && exit 0
        echo "$CHOICE" | cliphist decode | wl-copy
        ;;
    "$ADD_FAV")
        CHOICE=$(cliphist list | rofi -dmenu \
            -display-columns 2 \
            -p "Add Favorite" \
            -i \
            -theme "$ROFI_THEME")
        [ -z "$CHOICE" ] && exit 0
        DECODED=$(echo "$CHOICE" | cliphist decode)
        if grep -qF "$DECODED" "$FAVORITES"; then
            notify-send "Clipboard" "Already in favorites" --icon=dialog-information
        else
            echo "$DECODED" >> "$FAVORITES"
            notify-send "Clipboard" "Added to favorites" --icon=dialog-information
        fi
        ;;
    "$REMOVE_FAV")
        if [ ! -s "$FAVORITES" ]; then
            notify-send "Clipboard" "No favorites yet" --icon=dialog-information
            exit 0
        fi
        CHOICE=$(cat "$FAVORITES" | rofi -dmenu \
            -p "Remove Favorite" \
            -i \
            -theme "$ROFI_THEME")
        [ -z "$CHOICE" ] && exit 0
        grep -vF "$CHOICE" "$FAVORITES" > "$FAVORITES.tmp"
        mv "$FAVORITES.tmp" "$FAVORITES"
        notify-send "Clipboard" "Removed from favorites" --icon=dialog-information
        ;;
esac

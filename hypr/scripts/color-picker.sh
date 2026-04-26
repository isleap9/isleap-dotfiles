#!/bin/bash
color=$(hyprpicker --autocopy --no-fancy)

if [[ -n "$color" ]]; then
    notify-send "Color Picked" "$color" \
        --icon=color-picker \
        --app-name="Color Picker" \
        --hint=string:x-canonical-private-synchronous:color-picker
fi

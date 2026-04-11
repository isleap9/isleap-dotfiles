#!/bin/bash

# Paths
WAYBAR_THEMES="$HOME/.config/waybar/themes"
ROFI_COLORS="$HOME/.config/rofi/colors"

# Symlink targets
WAYBAR_ACTIVE="$WAYBAR_THEMES/active.css"
ROFI_ACTIVE="$ROFI_COLORS/active.rasi"

# Map display names → theme files
declare -A WAYBAR_THEME=(
    ["  One Dark"]="onedark.css"
    ["  Catppuccin Mocha"]="catppuccin-mocha.css"
)

declare -A ROFI_THEME=(
    ["  One Dark"]="isleaponedark.rasi"
    ["  Catppuccin Mocha"]="catppuccin-mocha.rasi"
)

# Build menu
MENU=$(printf '%s\n' "${!WAYBAR_THEME[@]}" | sort)

# Show rofi prompt
CHOICE=$(echo "$MENU" | rofi -dmenu \
    -p "Theme" \
    -i \
    -no-custom \
    -theme "$HOME/.config/rofi/theme-switcher.rasi")

# Exit if nothing selected
[ -z "$CHOICE" ] && exit 0

# Get selected files
WAYBAR_FILE="${WAYBAR_THEME[$CHOICE]}"
ROFI_FILE="${ROFI_THEME[$CHOICE]}"

# Validate files exist
if [ ! -f "$WAYBAR_THEMES/$WAYBAR_FILE" ]; then
    notify-send "Theme Switcher" "Waybar theme not found: $WAYBAR_FILE" --icon=dialog-error
    exit 1
fi

if [ ! -f "$ROFI_COLORS/$ROFI_FILE" ]; then
    notify-send "Theme Switcher" "Rofi theme not found: $ROFI_FILE" --icon=dialog-error
    exit 1
fi

# Swap symlinks
ln -sf "$WAYBAR_THEMES/$WAYBAR_FILE" "$WAYBAR_ACTIVE"
ln -sf "$ROFI_COLORS/$ROFI_FILE" "$ROFI_ACTIVE"

# Reload waybar
pkill waybar && waybar &disown

# Notify
notify-send "Theme Switcher" "Switched to $CHOICE" --icon=preferences-desktop-theme
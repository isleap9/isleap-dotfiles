#!/bin/bash

# Paths
WAYBAR_THEMES="$HOME/.config/waybar/themes"
ROFI_COLORS="$HOME/.config/rofi/colors"
SWAYNC_THEMES="$HOME/.config/swaync/themes-colors"
KITTY_THEMES="$HOME/.config/kitty/themes"
WLOGOUT_THEMES="$HOME/.config/wlogout/themes"

# Symlink targets
WAYBAR_ACTIVE="$WAYBAR_THEMES/active.css"
ROFI_ACTIVE="$ROFI_COLORS/active.rasi"
SWAYNC_ACTIVE="$SWAYNC_THEMES/active.css"
KITTY_ACTIVE="$KITTY_THEMES/active.conf"
WLOGOUT_ACTIVE="$HOME/.config/wlogout/style.css"

# Map display names → theme files
declare -A WAYBAR_THEME=(
    ["  One Dark"]="onedark.css"
    ["  Catppuccin Mocha"]="catppuccin-mocha.css"
    ["  Gruvbox Dark"]="gruvbox.css"
    ["  Rosé Pine Moon"]="rosepine-moon.css" 
    ["  Rosé Pine Dawn"]="rosepine-dawn.css" 
)

declare -A ROFI_THEME=(
    ["  One Dark"]="isleaponedark.rasi"
    ["  Catppuccin Mocha"]="catppuccin-mocha.rasi"
    ["  Gruvbox Dark"]="gruvbox.rasi"
    ["  Rosé Pine Moon"]="rosepine-moon.rasi"
    ["  Rosé Pine Dawn"]="rosepine-dawn.rasi"
)

declare -A SWAYNC_THEME=(
    ["  One Dark"]="onedark.css"
    ["  Catppuccin Mocha"]="catppuccin-mocha.css"
    ["  Gruvbox Dark"]="gruvbox.css"
    ["  Rosé Pine Moon"]="rosepine-moon.css" 
    ["  Rosé Pine Dawn"]="rosepine-dawn.css" 
)

declare -A KITTY_THEME=(
    ["  One Dark"]="onedark.conf"
    ["  Catppuccin Mocha"]="catppuccin-mocha.conf"
    ["  Gruvbox Dark"]="gruvbox.conf"
    ["  Rosé Pine Moon"]="rosepine-moon.conf"
    ["  Rosé Pine Dawn"]="rosepine-dawn.conf" 
)

declare -A WLOGOUT_THEME=(
    ["  One Dark"]="onedark.css"
    ["  Catppuccin Mocha"]="catppuccin-mocha.css"
    ["  Gruvbox Dark"]="gruvbox.css"
    ["  Rosé Pine Moon"]="rosepine-moon.css" 
    ["  Rosé Pine Dawn"]="rosepine-dawn.css" 
)

# Hyprland border colors per theme
declare -A HYPR_ACTIVE_BORDER=(
    ["  One Dark"]="rgb(61AFEF)"
    ["  Catppuccin Mocha"]="rgb(cba6f7)"
    ["  Gruvbox Dark"]="rgb(fabd2f)"
    ["  Rosé Pine Moon"]="rgb(c4a7e7)" 
    ["  Rosé Pine Dawn"]="rgb(907aa9)"
)

declare -A HYPR_INACTIVE_BORDER=(
    ["  One Dark"]="rgb(282C34)"
    ["  Catppuccin Mocha"]="rgb(1e1e2e)"
    ["  Gruvbox Dark"]="rgb(282828)"
    ["  Rosé Pine Moon"]="rgb(232136)"
    ["  Rosé Pine Dawn"]="rgb(dfdad9)"
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
SWAYNC_FILE="${SWAYNC_THEME[$CHOICE]}"
KITTY_FILE="${KITTY_THEME[$CHOICE]}"
WLOGOUT_FILE="${WLOGOUT_THEME[$CHOICE]}"

# Validate files exist
if [ ! -f "$WAYBAR_THEMES/$WAYBAR_FILE" ]; then
    notify-send "Theme Switcher" "Waybar theme not found: $WAYBAR_FILE" --icon=dialog-error
    exit 1
fi

if [ ! -f "$ROFI_COLORS/$ROFI_FILE" ]; then
    notify-send "Theme Switcher" "Rofi theme not found: $ROFI_FILE" --icon=dialog-error
    exit 1
fi

if [ ! -f "$SWAYNC_THEMES/$SWAYNC_FILE" ]; then
    notify-send "Theme Switcher" "Swaync theme not found: $SWAYNC_FILE" --icon=dialog-error
    exit 1
fi

if [ ! -f "$KITTY_THEMES/$KITTY_FILE" ]; then
    notify-send "Theme Switcher" "Kitty theme not found: $KITTY_FILE" --icon=dialog-error
    exit 1
fi

if [ ! -f "$WLOGOUT_THEMES/$WLOGOUT_FILE" ]; then
    notify-send "Theme Switcher" "Wlogout theme not found: $WLOGOUT_FILE" --icon=dialog-error
    exit 1
fi

# Swap symlinks
ln -sf "$WAYBAR_THEMES/$WAYBAR_FILE" "$WAYBAR_ACTIVE"
ln -sf "$ROFI_COLORS/$ROFI_FILE" "$ROFI_ACTIVE"
ln -sf "$SWAYNC_THEMES/$SWAYNC_FILE" "$SWAYNC_ACTIVE"
ln -sf "$KITTY_THEMES/$KITTY_FILE" "$KITTY_ACTIVE"
ln -sf "$WLOGOUT_THEMES/$WLOGOUT_FILE" "$WLOGOUT_ACTIVE"

# Apply hyprland border colors instantly
hyprctl keyword general:col.active_border "${HYPR_ACTIVE_BORDER[$CHOICE]}"
hyprctl keyword general:col.inactive_border "${HYPR_INACTIVE_BORDER[$CHOICE]}"

# Reload waybar
pkill waybar && waybar &disown

# Reload swaync
swaync-client --reload-css &disown

# Reload kitty
pkill -USR1 kitty

# Notify
notify-send "Theme Switcher" "Switched to $CHOICE" --icon=preferences-desktop-theme
#!/bin/bash

# Paths
WAYBAR_THEMES="$HOME/.config/waybar/themes"
ROFI_COLORS="$HOME/.config/rofi/colors"
SWAYNC_THEMES="$HOME/.config/swaync/themes-colors"
KITTY_THEMES="$HOME/.config/kitty/themes"
WLOGOUT_THEMES="$HOME/.config/wlogout/themes"
HYPR_THEMES="$HOME/.config/hypr/modules/themes"

# Symlink targets
WAYBAR_ACTIVE="$WAYBAR_THEMES/active.css"
ROFI_ACTIVE="$ROFI_COLORS/active.rasi"
SWAYNC_ACTIVE="$SWAYNC_THEMES/active.css"
KITTY_ACTIVE="$KITTY_THEMES/active.conf"
WLOGOUT_ACTIVE="$HOME/.config/wlogout/style.css"
HYPR_ACTIVE="$HOME/.config/hypr/modules/active.conf"

# Map display names → theme files
declare -A WAYBAR_THEME=(
    ["  One Dark"]="onedark.css"
    ["  Catppuccin Mocha"]="catppuccin-mocha.css"
    ["  Gruvbox Dark"]="gruvbox.css"
    ["  Rosé Pine Moon"]="rosepine-moon.css"
    ["  Rosé Pine Dawn"]="rosepine-dawn.css"
    ["  E-Ink"]="eink.css"
    ["  Tokyo Night"]="tokyo-night.css"
    ["  Monokai Pro"]="monokai-pro.css" 
    ["  Cyberdream"]="cyberdream.css"
    ["  Catppuccin Frappe"]="catppuccin-frappe.css"
    ["  Catppuccin Latte"]="catppuccin-latte.css"
)

declare -A ROFI_THEME=(
    ["  One Dark"]="isleaponedark.rasi"
    ["  Catppuccin Mocha"]="catppuccin-mocha.rasi"
    ["  Gruvbox Dark"]="gruvbox.rasi"
    ["  Rosé Pine Moon"]="rosepine-moon.rasi"
    ["  Rosé Pine Dawn"]="rosepine-dawn.rasi"
    ["  E-Ink"]="eink.rasi"
    ["  Tokyo Night"]="tokyo-night.rasi" 
    ["  Monokai Pro"]="monokai-pro.rasi"
    ["  Cyberdream"]="cyberdream.rasi"
    ["  Catppuccin Frappe"]="catppuccin-frappe.rasi"
    ["  Catppuccin Latte"]="catppuccin-latte.rasi"
)

declare -A SWAYNC_THEME=(
    ["  One Dark"]="onedark.css"
    ["  Catppuccin Mocha"]="catppuccin-mocha.css"
    ["  Gruvbox Dark"]="gruvbox.css"
    ["  Rosé Pine Moon"]="rosepine-moon.css"
    ["  Rosé Pine Dawn"]="rosepine-dawn.css"
    ["  E-Ink"]="eink.css"
    ["  Tokyo Night"]="tokyo-night.css"
    ["  Monokai Pro"]="monokai-pro.css" 
    ["  Cyberdream"]="cyberdream.css"
    ["  Catppuccin Frappe"]="catppuccin-frappe.css"
    ["  Catppuccin Latte"]="catppuccin-latte.css"
)

declare -A KITTY_THEME=(
    ["  One Dark"]="onedark.conf"
    ["  Catppuccin Mocha"]="catppuccin-mocha.conf"
    ["  Gruvbox Dark"]="gruvbox.conf"
    ["  Rosé Pine Moon"]="rosepine-moon.conf"
    ["  Rosé Pine Dawn"]="rosepine-dawn.conf"
    ["  E-Ink"]="eink.conf"
    ["  Tokyo Night"]="tokyo-night.conf"
    ["  Monokai Pro"]="monokai-pro.conf"
    ["  Cyberdream"]="cyberdream.conf"
    ["  Catppuccin Frappe"]="catppuccin-frappe.conf"
    ["  Catppuccin Latte"]="catppuccin-latte.conf"
)

declare -A WLOGOUT_THEME=(
    ["  One Dark"]="onedark.css"
    ["  Catppuccin Mocha"]="catppuccin-mocha.css"
    ["  Gruvbox Dark"]="gruvbox.css"
    ["  Rosé Pine Moon"]="rosepine-moon.css"
    ["  Rosé Pine Dawn"]="rosepine-dawn.css"
    ["  E-Ink"]="eink.css"
    ["  Tokyo Night"]="tokyo-night.css"
    ["  Monokai Pro"]="monokai-pro.css" 
    ["  Cyberdream"]="cyberdream.css"
    ["  Catppuccin Frappe"]="catppuccin-frappe.css"
    ["  Catppuccin Latte"]="catppuccin-latte.css"
)

declare -A KDE_THEME=(
    ["  One Dark"]="OneDark"
    ["  Catppuccin Mocha"]="CatppuccinMocha"
    ["  Gruvbox Dark"]="GruvboxDark"
    ["  Rosé Pine Moon"]="RosePineMoon"
    ["  Rosé Pine Dawn"]="RosePineDawn"
    ["  E-Ink"]="EInk"
    ["  Tokyo Night"]="TokyoNight" 
    ["  Monokai Pro"]="MonokaiPro" 
    ["  Cyberdream"]="Cyberdream" 
    ["  Catppuccin Frappe"]="CatppuccinFrappe" 
    ["  Catppuccin Latte"]="CatppuccinLatte" 
)

declare -A HYPR_THEME=(
    ["  One Dark"]="onedark.conf"
    ["  Catppuccin Mocha"]="catppuccin-mocha.conf"
    ["  Gruvbox Dark"]="gruvbox.conf"
    ["  Rosé Pine Moon"]="rosepine-moon.conf"
    ["  Rosé Pine Dawn"]="rosepine-dawn.conf"
    ["  E-Ink"]="eink.conf"
    ["  Tokyo Night"]="tokyo-night.conf" 
    ["  Monokai Pro"]="monokai-pro.conf"
    ["  Cyberdream"]="cyberdream.conf"
    ["  Catppuccin Frappe"]="catppuccin-frappe.conf"
    ["  Catppuccin Latte"]="catppuccin-latte.conf"
)

# Hyprland border colors per theme (for instant runtime apply)
declare -A HYPR_ACTIVE_BORDER=(
    ["  One Dark"]="rgb(61AFEF)"
    ["  Catppuccin Mocha"]="rgb(cba6f7)"
    ["  Gruvbox Dark"]="rgb(fabd2f)"
    ["  Rosé Pine Moon"]="rgb(c4a7e7)"
    ["  Rosé Pine Dawn"]="rgb(907aa9)"
    ["  E-Ink"]="rgb(1a1a1a)"
    ["  Tokyo Night"]="rgb(7aa2f7)" 
    ["  Monokai Pro"]="rgb(f92672)" 
    ["  Cyberdream"]="rgb(df80ff)" 
    ["  Catppuccin Frappe"]="rgb(ca9ee6)" 
    ["  Catppuccin Latte"]="rgb(8839ef)" 
)

declare -A HYPR_INACTIVE_BORDER=(
    ["  One Dark"]="rgb(282C34)"
    ["  Catppuccin Mocha"]="rgb(1e1e2e)"
    ["  Gruvbox Dark"]="rgb(282828)"
    ["  Rosé Pine Moon"]="rgb(232136)"
    ["  Rosé Pine Dawn"]="rgb(dfdad9)"
    ["  E-Ink"]="rgb(d0d0d0)"
    ["  Tokyo Night"]="rgb(1a1b26)"  
    ["  Monokai Pro"]="rgb(272822)" 
    ["  Cyberdream"]="rgb(16181a)"
    ["  Catppuccin Frappe"]="rgb(303446)" 
    ["  Catppuccin Latte"]="rgb(eff1f5)" 
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
HYPR_FILE="${HYPR_THEME[$CHOICE]}"

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

if [ ! -f "$HYPR_THEMES/$HYPR_FILE" ]; then
    notify-send "Theme Switcher" "Hyprland theme not found: $HYPR_FILE" --icon=dialog-error
    exit 1
fi

# Swap symlinks
ln -sf "$WAYBAR_THEMES/$WAYBAR_FILE" "$WAYBAR_ACTIVE"
ln -sf "$ROFI_COLORS/$ROFI_FILE" "$ROFI_ACTIVE"
ln -sf "$SWAYNC_THEMES/$SWAYNC_FILE" "$SWAYNC_ACTIVE"
ln -sf "$KITTY_THEMES/$KITTY_FILE" "$KITTY_ACTIVE"
ln -sf "$WLOGOUT_THEMES/$WLOGOUT_FILE" "$WLOGOUT_ACTIVE"
ln -sf "$HYPR_THEMES/$HYPR_FILE" "$HYPR_ACTIVE"

# Apply hyprland border colors instantly (runtime)
hyprctl keyword general:col.active_border "${HYPR_ACTIVE_BORDER[$CHOICE]}"
hyprctl keyword general:col.inactive_border "${HYPR_INACTIVE_BORDER[$CHOICE]}"

# Apply plasma colorscheme

plasma-apply-colorscheme "${KDE_THEME[$CHOICE]}"

# Reload waybar
pkill waybar && waybar &disown

# Reload swaync
swaync-client --reload-css &disown

# Reload kitty
pkill -USR1 kitty

# Notify
notify-send "Theme Switcher" "Switched to $CHOICE" --icon=preferences-desktop-theme
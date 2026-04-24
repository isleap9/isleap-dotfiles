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
    ["  Oxocarbon"]="oxocarbon.css"
    ["  Tokyo Day"]="tokyo-day.css"
    ["  Papercolor"]="papercolor.css"
    ["  Dracula"]="dracula.css" 
    ["  Dracula Light"]="dracula-light.css" 
    ["  Crimson"]="crimson.css" 
    ["  Sakura"]="sakura.css" 
    ["  Everforest Dark"]="everforest-dark.css" 
    ["  Everforest Light"]="everforest-light.css"
    ["  Kanagawa Dark"]="kanagawa-dark.css" 
    ["  Kanagawa Light"]="kanagawa-light.css"
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
    ["  Oxocarbon"]="oxocarbon.rasi"
    ["  Tokyo Day"]="tokyo-day.rasi"
    ["  Papercolor"]="papercolor.rasi"
    ["  Dracula"]="dracula.rasi"
    ["  Dracula Light"]="dracula-light.rasi"
    ["  Crimson"]="crimson.rasi"
    ["  Sakura"]="sakura.rasi" 
    ["  Everforest Dark"]="everforest-dark.rasi"
    ["  Everforest Light"]="everforest-light.rasi"
    ["  Kanagawa Dark"]="kanagawa-dark.rasi" 
    ["  Kanagawa Light"]="kanagawa-light.rasi"
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
    ["  Oxocarbon"]="oxocarbon.css"
    ["  Tokyo Day"]="tokyo-day.css"
    ["  Papercolor"]="papercolor.css"
    ["  Dracula"]="dracula.css" 
    ["  Dracula Light"]="dracula-light.css" 
    ["  Crimson"]="crimson.css" 
    ["  Sakura"]="sakura.css" 
    ["  Everforest Dark"]="everforest-dark.css" 
    ["  Everforest Light"]="everforest-light.css"
    ["  Kanagawa Dark"]="kanagawa-dark.css" 
    ["  Kanagawa Light"]="kanagawa-light.css"
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
    ["  Oxocarbon"]="oxocarbon.conf"
    ["  Tokyo Day"]="tokyo-day.conf"
    ["  Papercolor"]="papercolor.conf"
    ["  Dracula"]="dracula.conf" 
    ["  Dracula Light"]="dracula-light.conf" 
    ["  Crimson"]="crimson.conf"
    ["  Sakura"]="sakura.conf" 
    ["  Everforest Dark"]="everforest-dark.conf"
    ["  Everforest Light"]="everforest-light.conf"
    ["  Kanagawa Dark"]="kanagawa-dark.conf"
    ["  Kanagawa Light"]="kanagawa-light.conf"
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
    ["  Oxocarbon"]="oxocarbon.css"
    ["  Tokyo Day"]="tokyo-day.css"
    ["  Papercolor"]="papercolor.css"
    ["  Dracula"]="dracula.css" 
    ["  Dracula Light"]="dracula-light.css" 
    ["  Crimson"]="crimson.css" 
    ["  Sakura"]="sakura.css" 
    ["  Everforest Dark"]="everforest-dark.css" 
    ["  Everforest Light"]="everforest-light.css"
    ["  Kanagawa Dark"]="kanagawa-dark.css" 
    ["  Kanagawa Light"]="kanagawa-light.css"
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
    ["  Oxocarbon"]="Oxocarbon" 
    ["  Tokyo Day"]="TokyoDay"
    ["  Papercolor"]="Papercolor" 
    ["  Dracula"]="Dracula" 
    ["  Dracula Light"]="DraculaLight" 
    ["  Crimson"]="CrimsonDark" 
    ["  Sakura"]="SakuraLight" 
    ["  Everforest Dark"]="EverforestDark" 
    ["  Everforest Light"]="EverforestLight" 
    ["  Kanagawa Dark"]="KanagawaDark" 
    ["  Kanagawa Light"]="KanagawaLight" 
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
    ["  Oxocarbon"]="oxocarbon.conf"
    ["  Tokyo Day"]="tokyo-day.conf"
    ["  Papercolor"]="papercolor.conf"
    ["  Dracula"]="dracula.conf" 
    ["  Dracula Light"]="dracula-light.conf" 
    ["  Crimson"]="crimson.conf"
    ["  Sakura"]="sakura.conf" 
    ["  Everforest Dark"]="everforest-dark.conf"
    ["  Everforest Light"]="everforest-light.conf"
    ["  Kanagawa Dark"]="kanagawa-dark.conf"
    ["  Kanagawa Light"]="kanagawa-light.conf"
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
    ["  Oxocarbon"]="rgb(ff7eb6)" 
    ["  Tokyo Day"]="rgb(2e7de9)"   
    ["  Papercolor"]="rgb(0087af)"
    ["  Dracula"]="rgb(bd93f9)"   
    ["  Dracula Light"]="rgb(7c4dbd)"
    ["  Crimson"]="rgb(cc1133)"
    ["  Sakura"]="rgb(cc0044)" 
    ["  Everforest Dark"]="rgb(a7c080)"
    ["  Everforest Light"]="rgb(8da101)"
    ["  Kanagawa Dark"]="rgb(e46876)"  
    ["  Kanagawa Light"]="rgb(c84053)" 
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
    ["  Oxocarbon"]="rgb(161616)"
    ["  Tokyo Day"]="rgb(e1e2e7)" 
    ["  Papercolor"]="rgb(eeeeee)"
    ["  Dracula"]="rgb(282a36)" 
    ["  Dracula Light"]="rgb(f8f8f2)" 
    ["  Crimson"]="rgb(1a0a0a)" 
    ["  Sakura"]="rgb(fff5f7)" 
    ["  Everforest Dark"]="rgb(2d353b)" 
    ["  Everforest Light"]="rgb(fdf6e3)" 
    ["  Kanagawa Dark"]="rgb(1f1f28)" 
    ["  Kanagawa Light"]="rgb(f2ecbc)" 
)

declare -A CAL_MONTHS=(
    ["  One Dark"]="#61AFEF"
    ["  Catppuccin Mocha"]="#cba6f7"
    ["  Gruvbox Dark"]="#fabd2f"
    ["  Rosé Pine Moon"]="#c4a7e7"
    ["  Rosé Pine Dawn"]="#907aa9"
    ["  E-Ink"]="#333333"
    ["  Tokyo Night"]="#7aa2f7"
    ["  Monokai Pro"]="#f92672"
    ["  Cyberdream"]="#df80ff"
    ["  Catppuccin Frappe"]="#ca9ee6"
    ["  Catppuccin Latte"]="#8839ef"
    ["  Oxocarbon"]="#ff7eb6"
    ["  Tokyo Day"]="#2e7de9"
    ["  Papercolor"]="#0087af"
    ["  Monokai Pro"]="#f92672"
    ["  Tokyo Night"]="#7aa2f7"
    ["  Dracula"]="#bd93f9"
    ["  Dracula Light"]="#7c4dbd"
    ["  Crimson"]="#cc1133"
    ["  Sakura"]="#cc0044"
    ["  Everforest Dark"]="#a7c080"
    ["  Everforest Light"]="#8da101"
    ["  Kanagawa Dark"]="#e46876"
    ["  Kanagawa Light"]="#c84053"

)

declare -A CAL_DAYS=(
    ["  One Dark"]="#abb2bf"
    ["  Catppuccin Mocha"]="#cdd6f4"
    ["  Gruvbox Dark"]="#ebdbb2"
    ["  Rosé Pine Moon"]="#e0def4"
    ["  Rosé Pine Dawn"]="#575279"
    ["  E-Ink"]="#333333"
    ["  Tokyo Night"]="#c0caf5"
    ["  Monokai Pro"]="#fcfcfa"
    ["  Cyberdream"]="#ffffff"
    ["  Catppuccin Frappe"]="#c6d0f5"
    ["  Catppuccin Latte"]="#4c4f69"
    ["  Oxocarbon"]="#f2f4f8"
    ["  Tokyo Day"]="#3760bf"
    ["  Papercolor"]="#444444"
    ["  Monokai Pro"]="#f8f8f2"
    ["  Tokyo Night"]="#c0caf5"
    ["  Dracula"]="#f8f8f2"
    ["  Dracula Light"]="#282a36"
    ["  Crimson"]="#f5e6e6"
    ["  Sakura"]="#4a1528"
    ["  Everforest Dark"]="#d3c6aa"
    ["  Everforest Light"]="#5c6a72"
    ["  Kanagawa Dark"]="#dcd7ba"
    ["  Kanagawa Light"]="#545464"
)

declare -A CAL_WEEKDAYS=(
    ["  One Dark"]="#e5c07b"
    ["  Catppuccin Mocha"]="#f9e2af"
    ["  Gruvbox Dark"]="#fabd2f"
    ["  Rosé Pine Moon"]="#f6c177"
    ["  Rosé Pine Dawn"]="#ea9d34"
    ["  E-Ink"]="#333333"
    ["  Tokyo Night"]="#e0af68"
    ["  Monokai Pro"]="#ffd866"
    ["  Cyberdream"]="#f6f600"
    ["  Catppuccin Frappe"]="#e5c890"
    ["  Catppuccin Latte"]="#df8e1d"
    ["  Oxocarbon"]="#fddc69"
    ["  Tokyo Day"]="#8c6c3e"
    ["  Papercolor"]="#d75f00"
    ["  Monokai Pro"]="#e6db74"
    ["  Tokyo Night"]="#e0af68"
    ["  Dracula"]="#f1fa8c"
    ["  Dracula Light"]="#8b8b00"
    ["  Crimson"]="#ffcc66"
    ["  Sakura"]="#996600"
    ["  Everforest Dark"]="#dbbc7f"
    ["  Everforest Light"]="#dfa000"
    ["  Kanagawa Dark"]="#c0a36e"
    ["  Kanagawa Light"]="#77713f"
)

# Build menu
MENU=$(printf '%s\n' "󰁍  Back to Control Center" "${!WAYBAR_THEME[@]}" | sort)

# Show rofi prompt
CHOICE=$(echo "$MENU" | rofi -dmenu \
    -p "Theme" \
    -i \
    -no-custom \
    -theme "$HOME/.config/rofi/theme-switcher.rasi")

# Exit if nothing selected
[ -z "$CHOICE" ] && exit 0

# Handle back button
if [[ "$CHOICE" == *"Back to Control Center"* ]]; then
    bash "$HOME/.config/rofi/scripts/control-center.sh"
    exit 0
fi

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

# Update calendar colors
for CONFIG in \
    "$HOME/.config/waybar/configs/default.jsonc" \
    "$HOME/.config/waybar/configs/default2.jsonc"; do
    sed -i "s|\"months\": \"<span color='[^']*'>|\"months\": \"<span color='${CAL_MONTHS[$CHOICE]}'>|g" "$CONFIG"
    sed -i "s|\"days\": \"<span color='[^']*'>|\"days\": \"<span color='${CAL_DAYS[$CHOICE]}'>|g" "$CONFIG"
    sed -i "s|\"weekdays\": \"<span color='[^']*'>|\"weekdays\": \"<span color='${CAL_WEEKDAYS[$CHOICE]}'>|g" "$CONFIG"
done

# Apply hyprland border colors instantly (runtime)
hyprctl keyword general:col.active_border "${HYPR_ACTIVE_BORDER[$CHOICE]}"
hyprctl keyword general:col.inactive_border "${HYPR_INACTIVE_BORDER[$CHOICE]}"

# Apply plasma colorscheme

plasma-apply-colorscheme "${KDE_THEME[$CHOICE]}"

# Reload waybar
LAYOUT=$(cat "$HOME/.config/waybar/current-layout" 2>/dev/null || echo "default")
pkill waybar
waybar --config "$HOME/.config/waybar/configs/${LAYOUT}.jsonc" --style "$HOME/.config/waybar/styles/${LAYOUT}.css" &disown

# Reload swaync
swaync-client --reload-css &disown

# Reload kitty
pkill -USR1 kitty

# Notify
notify-send "Theme Switcher" "Switched to $CHOICE" --icon=preferences-desktop-theme

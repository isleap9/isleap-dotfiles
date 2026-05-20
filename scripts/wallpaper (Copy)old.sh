#!/usr/bin/env bash
echo "Wallpaper: $1" >> /tmp/wallpaper.log
awww img "$1"
wal -i "$1" -n -q
# Generate waybar colors.css from pywal
source ~/.cache/wal/colors.sh
cat > ~/.config/waybar/colors.css << EOF
@define-color bg0 $color0;
@define-color bg1 $color0;
@define-color bg2 $color1;
@define-color bg3 $color2;
@define-color bg4 $color3;
@define-color surface $color8;
@define-color fg $foreground;
@define-color red $color1;
@define-color orange $color3;
@define-color yellow $color4;
@define-color green $color2;
@define-color aqua $color6;
@define-color blue $color4;
@define-color purple $color5;
@define-color gray0 $color7;
@define-color gray1 $color8;
@define-color gray2 $color8;
EOF

# Update Hyprland borders
source ~/.cache/wal/colors.sh
hyprctl keyword general:col.active_border "rgb(${color2//#/})"
hyprctl keyword general:col.inactive_border "rgb(${color0//#/})"

# Update rofi colors
cat > ~/.config/rofi/colors/pywal.rasi << EOF
* {
    background:     ${background}FF;
    background-alt: ${color0}FF;
    foreground:     ${foreground}FF;
    selected:       ${color2}FF;
    active:         ${color3}FF;
    urgent:         ${color1}FF;
}
EOF

# Update swaync colors
cat > ~/.config/swaync/colors.css << EOF
@define-color bg0 ${color0};
@define-color bg1 ${color8};
@define-color bg2 ${color1};
@define-color bg3 ${color2};
@define-color bg4 ${color3};
@define-color fg ${foreground};
@define-color red ${color1};
@define-color orange ${color3};
@define-color yellow ${color4};
@define-color green ${color2};
@define-color aqua ${color6};
@define-color blue ${color4};
@define-color purple ${color5};
@define-color gray0 ${color7};
@define-color gray1 ${color8};
@define-color gray2 ${color8};
EOF
swaync-client -R

pkill swaync; sleep 0.5 && swaync &

# Update wlogout colors
cat > ~/.config/wlogout/style.css << EOF
* {
    background-image: none;
    box-shadow: none;
}
window {
    background-color: rgba(0,0,0,0.5);
}
button {
    border-radius: 12px;
    border-color: ${color0};
    text-decoration-color: ${foreground};
    color: ${foreground};
    background-color: ${color0};
    border-style: solid;
    border-width: 1px;
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
}
button:focus, button:active, button:hover {
    background-color: ${color2};
    outline-style: none;
}
#lock {
    background-image: image(url("/usr/share/wlogout/icons/lock.png"), url("/usr/local/share/wlogout/icons/lock.png"));
}
#logout {
    background-image: image(url("/usr/share/wlogout/icons/logout.png"), url("/usr/local/share/wlogout/icons/logout.png"));
}
#suspend {
    background-image: image(url("/usr/share/wlogout/icons/suspend.png"), url("/usr/local/share/wlogout/icons/suspend.png"));
}
#hibernate {
    background-image: image(url("/usr/share/wlogout/icons/hibernate.png"), url("/usr/local/share/wlogout/icons/hibernate.png"));
}
#shutdown {
    background-image: image(url("/usr/share/wlogout/icons/shutdown.png"), url("/usr/local/share/wlogout/icons/shutdown.png"));
}
#reboot {
    background-image: image(url("/usr/share/wlogout/icons/reboot.png"), url("/usr/local/share/wlogout/icons/reboot.png"));
}
EOF

# Update starship colors
cat > ~/.config/starship-colors.toml << EOF
[palettes.ccswe_dark]
color_bg1 = "${color1}"
color_bg2 = "${color2}"
color_bg3 = "${color3}"
color_bg4 = "${color4}"
color_bg5 = "${color0}"
color_blue = "${color4}"
color_gray = "${color8}"
color_red = "${color1}"
color_white = "${foreground}"
EOF

sleep 0.3
pkill waybar && waybar &

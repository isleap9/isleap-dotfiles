#################
--- AUTOSTART ---
#################

hl.exec_once("hyprctl setcursor Bibata-Modern-Ice 20")

hl.exec_once("/usr/lib/polkit-kde-authentication-agent-1")
hl.exec_once("awww-daemon")
hl.exec_once("~/.config/waybar/scripts/launch.sh")

hl.exec_once("wl-paste --type text --watch cliphist store")
hl.exec_once("wl-paste --type image --watch cliphist store")

hl.exec_once("wl-clip-persist --clipboard regular")

hl.exec_once("arch-update --tray")

hl.exec_once("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

hl.exec_once("hypridle")

hl.exec_once("/usr/lib/gnome-settings-daemon/gsd-xsettings")
hl.exec_once("/usr/lib/gsd-xsettings")

hl.exec_once("~/.config/hypr/scripts/spotify-notify.sh")

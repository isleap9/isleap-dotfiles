--- AUTOSTART ---

os.execute("hyprctl setcursor Bibata-Modern-Ice 20 &")

os.execute("/usr/lib/polkit-kde-authentication-agent-1 &")
os.execute("awww-daemon &")
os.execute("~/.config/waybar/scripts/launch.sh &")

os.execute("wl-paste --type text --watch cliphist store &")
os.execute("wl-paste --type image --watch cliphist store &")

os.execute("wl-clip-persist --clipboard regular &")

os.execute("arch-update --tray &")

os.execute("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &")

os.execute("hypridle &")

os.execute("/usr/lib/gnome-settings-daemon/gsd-xsettings &")
os.execute("/usr/lib/gsd-xsettings &")

os.execute("~/.config/hypr/scripts/spotify-notify.sh &")

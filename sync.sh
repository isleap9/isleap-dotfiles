#!/usr/bin/env bash
# sync.sh — copy the configs from this machine into the repo.
# Then review and commit the changes (e.g. in GitHub Desktop).
#
# The repo mirrors the real locations:
#   config/       -> ~/.config/
#   local/share/  -> ~/.local/share/
#   Wallpapers/   -> ~/Pictures/Wallpapers/
#   extras/       -> things install.sh sets up (wallpaper picker settings + patch)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
SHARE="$HOME/.local/share"

# Replace DEST with a fresh copy of SRC, so files deleted locally disappear from the repo too
mirror() {
    local src="$1" dest="$2"
    [[ -e "$src" ]] || { echo "  skip (missing): $src"; return; }
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
}

echo "==> ~/.config"
for dir in hypr quickshell qylock kitty matugen btop fastfetch cliphist menus xdg-desktop-portal; do
    mirror "$CFG/$dir" "$DOTFILES/config/$dir"
done
for file in starship.toml mimeapps.list; do
    mirror "$CFG/$file" "$DOTFILES/config/$file"
done

# fish: config and functions only (fish_variables is machine-specific)
rm -rf "$DOTFILES/config/fish"
mkdir -p "$DOTFILES/config/fish"
cp -a "$CFG/fish/config.fish" "$DOTFILES/config/fish/"
for dir in functions conf.d completions; do
    [[ -d "$CFG/fish/$dir" ]] && cp -a "$CFG/fish/$dir" "$DOTFILES/config/fish/"
done

# GTK: just the settings (bookmarks etc. are personal)
for gtk in gtk-3.0 gtk-4.0; do
    rm -rf "$DOTFILES/config/$gtk"
    mkdir -p "$DOTFILES/config/$gtk"
    cp -a "$CFG/$gtk/settings.ini" "$DOTFILES/config/$gtk/"
done

# Waybar is gone, but Quickshell still uses its theme files, theme switcher and weather script
rm -rf "$DOTFILES/config/waybar"
mkdir -p "$DOTFILES/config/waybar/scripts"
cp -a "$CFG/waybar/themes" "$DOTFILES/config/waybar/"
cp -a "$CFG/waybar/scripts/theme-switcher.sh" "$CFG/waybar/scripts/weather.py" "$DOTFILES/config/waybar/scripts/"
cp -a "$CFG/waybar/current-layout" "$DOTFILES/config/waybar/"

echo "==> ~/.local/share"
mirror "$SHARE/color-schemes" "$DOTFILES/local/share/color-schemes"
mirror "$SHARE/kio/servicemenus" "$DOTFILES/local/share/kio/servicemenus"
rm -rf "$DOTFILES/local/share/applications"
mkdir -p "$DOTFILES/local/share/applications"
cp -a "$SHARE/applications/arch-update.desktop" "$SHARE/applications/quickshell-settings.desktop" \
    "$DOTFILES/local/share/applications/"

echo "==> qs-wallpaper-picker (settings + local patch)"
PICKER="$CFG/qs-wallpaper-picker"
if [[ -d "$PICKER/.git" ]]; then
    mkdir -p "$DOTFILES/extras/qs-wallpaper-picker"
    cp -a "$PICKER/config/Settings.qml" "$DOTFILES/extras/qs-wallpaper-picker/"
    git -C "$PICKER" diff > "$DOTFILES/extras/qs-wallpaper-picker/local-changes.patch"
    git -C "$PICKER" rev-parse HEAD > "$DOTFILES/extras/qs-wallpaper-picker/UPSTREAM_COMMIT"
fi

echo "==> Wallpapers"
mirror "$HOME/Pictures/Wallpapers" "$DOTFILES/Wallpapers"

echo "==> Cleaning up"
# Leftover backup/scratch files
find "$DOTFILES/config" \( -name '*.bak' -o -name '*.bak-*' -o -name '* (Copy)*' \
    -o -name '*.shcurrentbackup' -o -name '*.shdadwasdsa' -o -name '*~' \) -prune -exec rm -rf {} +

# Turn absolute symlinks (/home/<you>/.config/...) into relative ones so they work for any user
python3 - "$DOTFILES" "$HOME" <<'EOF'
import os, sys
repo, home = sys.argv[1], sys.argv[2]
roots = {os.path.join(home, ".config"): os.path.join(repo, "config"),
         os.path.join(home, ".local/share"): os.path.join(repo, "local/share")}
for top in roots.values():
    for dirpath, dirnames, filenames in os.walk(top):
        for name in dirnames + filenames:
            link = os.path.join(dirpath, name)
            if not os.path.islink(link):
                continue
            target = os.readlink(link)
            if not os.path.isabs(target):
                continue
            for live, mirrored in roots.items():
                if target.startswith(live + "/"):
                    new = os.path.relpath(mirrored + target[len(live):], dirpath)
                    os.remove(link)
                    os.symlink(new, link)
                    break
EOF

echo
echo "Synced to $DOTFILES"
echo "Review and commit the changes in GitHub Desktop."

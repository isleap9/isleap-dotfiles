#!/usr/bin/env bash
# sync.sh — copy configs into the GitHub Desktop repo (commit/push from GitHub Desktop)

DOTFILES="$HOME/GitHub/isleap-dotfiles"

# Configs
cp -r ~/.config/hypr "$DOTFILES/"
cp -r ~/.config/waybar "$DOTFILES/"
cp -r ~/.config/rofi "$DOTFILES/"
cp -r ~/.config/kitty "$DOTFILES/"
cp -r ~/.config/swaync "$DOTFILES/"
cp -r ~/.config/wlogout "$DOTFILES/"
cp -r ~/.config/matugen "$DOTFILES/"
cp -r ~/.config/cliphist "$DOTFILES/"
cp -r ~/.config/menus "$DOTFILES/"
cp -r ~/.config/btop "$DOTFILES/"
cp -r ~/.config/fastfetch "$DOTFILES/"
cp -r ~/.config/fish "$DOTFILES/"
cp ~/.config/starship.toml "$DOTFILES/"
mkdir -p "$DOTFILES/gtk-3.0" "$DOTFILES/gtk-4.0"
cp ~/.config/gtk-3.0/settings.ini "$DOTFILES/gtk-3.0/"
cp ~/.config/gtk-4.0/settings.ini "$DOTFILES/gtk-4.0/"

# Wallpapers
mkdir -p "$DOTFILES/Wallpapers"
cp -r ~/Pictures/Wallpapers/* "$DOTFILES/Wallpapers/"

# KDE color schemes
mkdir -p "$DOTFILES/color-schemes"
cp ~/.local/share/color-schemes/*.colors "$DOTFILES/color-schemes/"

echo "Synced to $DOTFILES. Review and commit the changes in GitHub Desktop."

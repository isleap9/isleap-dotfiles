#!/usr/bin/env bash
# sync.sh — copy configs to dotfiles repo and push

DOTFILES="$HOME/isleap-dotfiles"

# Configs
cp -r ~/.config/hypr "$DOTFILES/"
cp -r ~/.config/waybar "$DOTFILES/"
cp -r ~/.config/rofi "$DOTFILES/"
cp -r ~/.config/kitty "$DOTFILES/"
cp -r ~/.config/swaync "$DOTFILES/"
cp -r ~/.config/wlogout "$DOTFILES/"
cp -r ~/.config/matugen "$DOTFILES/"
cp -r ~/.config/cliphist "$DOTFILES/"

# Wallpapers
mkdir -p "$DOTFILES/Wallpapers"
cp -r ~/Pictures/Wallpapers/* "$DOTFILES/Wallpapers/"

# KDE color schemes
mkdir -p "$DOTFILES/color-schemes"
cp ~/.local/share/color-schemes/*.colors "$DOTFILES/color-schemes/"

# Push
cd "$DOTFILES"
git add .
git commit -m "update configs"
git push

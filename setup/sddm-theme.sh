#!/usr/bin/env bash
# setup/sddm-theme.sh — use a qylock theme for the SDDM login screen (same look as the lock screen).
#
#   ./setup/sddm-theme.sh                  # Material You Dark
#   ./setup/sddm-theme.sh material-you     # the light version
#
# Run as your normal user; it asks for sudo. Needs the lock screen installed first (install.sh does that).
set -euo pipefail

THEME="${1:-material-you-dark}"
SRC="$HOME/.local/share/quickshell-lockscreen/themes_link/$THEME"
DEST="/usr/share/sddm/themes/$THEME"

[[ -d "$SRC" ]] || { echo "Theme not found: $SRC (install the qylock lock screen first)" >&2; exit 1; }

sudo rm -rf "$DEST"
sudo cp -r "$SRC" "$DEST"
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=%s\n' "$THEME" | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null

echo "SDDM login screen set to '$THEME' — you'll see it next time you log out or reboot."

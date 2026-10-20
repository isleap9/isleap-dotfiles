#!/usr/bin/env bash
# install.sh — set up isleap's Hyprland + Quickshell desktop on a fresh Arch Linux install.
#
#   git clone https://github.com/isleap9/isleap-dotfiles.git ~/GitHub/isleap-dotfiles
#   cd ~/GitHub/isleap-dotfiles && ./install.sh
#
# Run it as your normal user (it asks for sudo when needed). Safe to run again:
# existing configs are moved to ~/.config-backup-<date> before anything is copied.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# ── Helpers ──────────────────────────────────────────────────────────────────
bold=$'\e[1m'; green=$'\e[32m'; yellow=$'\e[33m'; red=$'\e[31m'; reset=$'\e[0m'
step() { echo; echo "${bold}${green}==>${reset}${bold} $*${reset}"; }
note() { echo "    $*"; }
warn() { echo "${yellow}  ! $*${reset}"; }
die()  { echo "${red}error: $*${reset}" >&2; exit 1; }
ask()  { # ask "question" default(y/n)
    local answer hint="[y/N]"; [[ "${2:-n}" == y ]] && hint="[Y/n]"
    read -rp "    $1 $hint " answer || true
    answer="${answer:-${2:-n}}"
    [[ "$answer" =~ ^[Yy] ]]
}

[[ $EUID -ne 0 ]] || die "run this as your normal user, not root"
command -v pacman >/dev/null || die "this script is for Arch Linux"

# ── Packages ─────────────────────────────────────────────────────────────────
PKGS=(
    # Hyprland and Wayland basics
    hyprland hypridle hyprpicker hyprshot grim slurp uwsm
    qt6-5compat qt6-svg   # needed by the qylock lock screen
    xdg-desktop-portal-hyprland xdg-desktop-portal-kde xdg-desktop-portal-gtk
    polkit-kde-agent qt5-wayland qt6-wayland
    # Quickshell (bar, launcher, notifications, control center, settings)
    quickshell qt6-multimedia qt6-multimedia-ffmpeg cava playerctl
    # Wallpaper and colors
    awww imagemagick ffmpeg
    # Terminal and shell
    kitty fish starship micro fastfetch btop
    # Dolphin and the apps it opens files with
    dolphin kio-extras kio-admin kde-cli-tools archlinux-xdg-menu plasma-integration breeze breeze-icons
    gwenview okular ark 7zip unrar unzip mpv
    kimageformats qt6-imageformats ffmpegthumbs kdegraphics-thumbnailers ffmpegthumbnailer
    # Clipboard and emoji
    wl-clipboard wl-clip-persist cliphist rofimoji
    # Audio, network, bluetooth, power
    pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber libpulse pavucontrol
    networkmanager network-manager-applet bluez bluez-utils brightnessctl power-profiles-daemon
    # System bits
    gnome-keyring seahorse xdg-user-dirs xdg-utils udisks2 libnotify jq curl wget git python glib2
    # Fonts
    ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-nerd-fonts-symbols otf-font-awesome
    noto-fonts noto-fonts-cjk noto-fonts-emoji
    # AUR
    matugen-bin bibata-cursor-theme ttf-google-sans ttf-rubik-vf arch-update mpvpaper
)
APPS=(google-chrome firefox visual-studio-code-bin github-desktop-bin discord)
# NVIDIA (set up for an RTX 5070): RTX 50 / Blackwell cards need the *open* kernel modules.
# nvidia-open is built for the stock "linux" kernel; any other kernel (zen, lts…) needs the DKMS version.
nvidia_packages() {
    local kernels others
    kernels="$(pacman -Qq 2>/dev/null | grep -E '^linux(-zen|-lts|-hardened|-rt)?$' || echo linux)"
    others="$(grep -v '^linux$' <<<"$kernels" || true)"
    if [[ -z "$others" ]]; then
        echo nvidia-open
    else
        echo nvidia-open-dkms
        for k in $kernels; do echo "$k-headers"; done
    fi
    echo nvidia-utils nvidia-settings libva-nvidia-driver
    # 32-bit driver for Steam / games, if multilib is enabled
    grep -q '^\[multilib\]' /etc/pacman.conf && echo lib32-nvidia-utils
}

step "Questions first (then it runs on its own)"
WANT_APPS=n;   ask "Install apps too (${APPS[*]})?" y && WANT_APPS=y
WANT_NVIDIA=n
# Detect an NVIDIA display card (vendor 0x10de, class 0x03xxxx) without needing lspci
if grep -l 0x10de /sys/bus/pci/devices/*/vendor 2>/dev/null | xargs -r dirname | xargs -r -I{} cat {}/class | grep -q '^0x03'; then
    note "NVIDIA GPU detected"
    ask "Install the NVIDIA driver (open kernel modules — needed for RTX 50 series)?" y && WANT_NVIDIA=y
else
    ask "No NVIDIA GPU detected. Install the NVIDIA driver anyway?" n && WANT_NVIDIA=y
fi
WANT_SDDM=n;   ask "Use the SDDM login screen?" y && WANT_SDDM=y

step "Installing yay (AUR helper)"
if command -v yay >/dev/null; then
    note "already installed"
else
    sudo pacman -S --needed --noconfirm git base-devel
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi

step "Installing packages (this takes a while)"
EXTRA=()
[[ $WANT_APPS == y ]] && EXTRA+=("${APPS[@]}")
if [[ $WANT_NVIDIA == y ]]; then
    mapfile -t NVIDIA < <(nvidia_packages | tr ' ' '\n')
    note "NVIDIA: ${NVIDIA[*]}"
    EXTRA+=("${NVIDIA[@]}")
fi
[[ $WANT_SDDM == y ]] && EXTRA+=(sddm)
yay -S --needed --noconfirm "${PKGS[@]}" "${EXTRA[@]}"

# ── Configs ──────────────────────────────────────────────────────────────────
step "Backing up existing configs to $BACKUP"
mkdir -p "$BACKUP"
for item in "$REPO"/config/*; do
    name="$(basename "$item")"
    if [[ -e "$HOME/.config/$name" ]]; then
        mv "$HOME/.config/$name" "$BACKUP/"
        note "moved ~/.config/$name"
    fi
done
rmdir "$BACKUP" 2>/dev/null && note "nothing to back up" || true

step "Copying configs"
mkdir -p "$HOME/.config" "$HOME/.local/share"
cp -a "$REPO/config/." "$HOME/.config/"
cp -a "$REPO/local/share/." "$HOME/.local/share/"
find "$HOME/.config/hypr/scripts" "$HOME/.config/quickshell/scripts" "$HOME/.config/waybar/scripts" \
    -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
chmod +x "$HOME/.local/share/kio/servicemenus/"*.desktop   # KDE only runs executable service menus

if [[ $WANT_NVIDIA == n ]]; then
    # The Hyprland env file has NVIDIA-only variables; comment them out on other GPUs
    sed -i '/^-- Nvidia/,/^$/ s/^hl\.env/-- hl.env/' "$HOME/.config/hypr/modules/env.lua"
    note "NVIDIA settings in hypr/modules/env.lua commented out"
fi

step "Wallpapers"
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
cp -an "$REPO/Wallpapers/." "$HOME/Pictures/Wallpapers/"
note "copied to ~/Pictures/Wallpapers"

step "Wallpaper picker (qs-wallpaper-picker)"
PICKER="$HOME/.config/qs-wallpaper-picker"
EXTRAS="$REPO/extras/qs-wallpaper-picker"
if [[ -d "$PICKER/.git" ]]; then
    note "already installed"
else
    git clone https://github.com/magetsu002/qs-wallpaper-picker.git "$PICKER"
    # Pin the version these settings were made for, then add the one-line local change
    git -C "$PICKER" -c advice.detachedHead=false checkout "$(cat "$EXTRAS/UPSTREAM_COMMIT")"
    git -C "$PICKER" apply "$EXTRAS/local-changes.patch"
fi
cp "$EXTRAS/Settings.qml" "$PICKER/config/Settings.qml"

step "Lock screen (qylock — Material You Dark)"
# Only the lock program and the two Material themes (the full repo is ~1.2 GB of other themes),
# pinned to the version this setup was made with. The chosen theme is in ~/.config/qylock/theme.
QYLOCK_COMMIT="f6561e2ceae33f26e5e660742a5df2f725cbe514"
LOCKDIR="$HOME/.local/share/quickshell-lockscreen"
tmp="$(mktemp -d)"
git clone -q --filter=blob:none --no-checkout https://github.com/Darkkal44/qylock.git "$tmp/qylock"
git -C "$tmp/qylock" sparse-checkout set --no-cone \
    /quickshell-lockscreen/ /themes/material-you/ /themes/material-you-dark/ /LICENSE
git -C "$tmp/qylock" -c advice.detachedHead=false checkout -q "$QYLOCK_COMMIT"
rm -rf "$LOCKDIR"
cp -r "$tmp/qylock/quickshell-lockscreen" "$LOCKDIR"
mkdir -p "$LOCKDIR/themes_link"
cp -r "$tmp/qylock/themes/material-you" "$tmp/qylock/themes/material-you-dark" "$LOCKDIR/themes_link/"
cp "$tmp/qylock/LICENSE" "$LOCKDIR/"
# Local fix: pressing Enter in the password field also unlocks the lock screen (upstream: login screen only)
patch -s -d "$LOCKDIR/themes_link/material-you-dark" -p1 < "$REPO/extras/qylock/material-you-dark-unlock-button.patch"
chmod +x "$LOCKDIR/lock.sh"
# Upstream bug: the Material themes only check the password when running as an SDDM login
# screen, so as a Quickshell lock screen Enter does nothing. Make Enter always check it.
for theme in material-you material-you-dark; do
    sed -i 's/if (!root.isQuickshell \&\& pwd.text !== "") {/if (pwd.text !== "") {   \/\/ patched: also unlock in Quickshell (was SDDM-only)/' \
        "$LOCKDIR/themes_link/$theme/Main.qml"
    grep -q 'patched: also unlock in Quickshell' "$LOCKDIR/themes_link/$theme/Main.qml" \
        || warn "couldn't patch $theme — unlocking may not work, check $LOCKDIR/themes_link/$theme/Main.qml"
done
rm -rf "$tmp"
note "installed to $LOCKDIR (SUPER+SHIFT+L, power menu, idle and sleep all use it)"
if [[ $WANT_SDDM == y ]]; then
    "$REPO/setup/sddm-theme.sh" material-you-dark   # same look for the login screen
fi

# ── Desktop integration ──────────────────────────────────────────────────────
step "Home folders (Documents, Music, Videos…)"
xdg-user-dirs-update
mkdir -p "$HOME/Projects" "$HOME/GitHub"

step "Dolphin: terminal, thumbnails, sidebar, Open With menu"
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
kwriteconfig6 --file kdeglobals --group PreviewSettings --key MaximumSize 104857600
kwriteconfig6 --file dolphinrc --group PreviewSettings --key Plugins \
    "appimagethumbnail,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,directorythumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,ffmpegthumbs,fontthumbnail,gsthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,mobithumbnail,opendocumentthumbnail,rawthumbnail,svgthumbnail,windowsexethumbnail,windowsimagethumbnail"
if pgrep -x dolphin >/dev/null; then
    warn "Dolphin is open — close it and run: python3 $REPO/setup/dolphin-places.py"
else
    python3 "$REPO/setup/dolphin-places.py"
fi
# Without this menu Dolphin's "Open With" list is empty outside KDE Plasma
XDG_MENU_PREFIX=arch- kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

step "GTK apps: dark mode and icons"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'breeze-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true

# ── Services ─────────────────────────────────────────────────────────────────
step "Services"
sudo systemctl enable NetworkManager.service bluetooth.service power-profiles-daemon.service
[[ $WANT_SDDM == y ]] && sudo systemctl enable sddm.service
systemctl --user enable gnome-keyring-daemon.socket   # saved logins (GitHub Desktop, Chrome…)
systemctl --user enable arch-update.timer             # checks for updates at boot and every 6 hours

# ── Done ─────────────────────────────────────────────────────────────────────
step "All done!"
note "Reboot, then log into Hyprland."
[[ -d "$BACKUP" ]] && note "Your previous configs are in $BACKUP"
note "SUPER+SPACE apps · SUPER+SHIFT+E control center · SUPER+, settings · SUPER+SHIFT+W wallpapers"
note "Monitors: edit ~/.config/hypr/modules/monitors.lua (or run nwg-displays) — it's set for isleap's two screens."

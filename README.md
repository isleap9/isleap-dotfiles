# 🌸 isleap's dotfiles
A Hyprland rice with a custom One Dark-based palette, centered island Waybar, and a clean minimal aesthetic.

---

## 📸 Preview
![Desktop](screenshots/1.png)
![Desktop2](screenshots/2.png)

---

## 🖥️ System Info
| | |
|---|---|
| **OS** | Arch Linux |
| **WM** | Hyprland |
| **Bar** | Waybar |
| **Terminal** | Kitty |
| **Shell** | Fish |
| **Launcher** | Rofi |
| **Notifications** | Swaync |
| **File Manager** | Dolphin |
| **Wallpaper** | Waypaper + awww |
| **Theming** | One Dark (custom) |
| **Cursor** | Bibata-Modern-Ice |
| **GPU** | NVIDIA (nvidia-open-dkms) |

---

## 📦 Packages

### 🪟 Hyprland & WM
```
hyprland polkit-kde-agent hyprshot
```

### 📊 Bar & Notifications
```
waybar swaync
```

### 🖼️ Wallpaper
```
awww waypaper
```

### 🚀 App Launcher
```
rofi
```

### 💻 Terminal
```
kitty
```

### 🔤 Fonts
```
ttf-rubik-vf
ttf-jetbrains-mono-nerd
google-sans-display (AUR)
ttf-firacode-nerd
ttf-nerd-fonts-symbols
otf-font-awesome
noto-fonts-cjk
```

### 🔊 Audio
```
pipewire pipewire-alsa pipewire-jack pipewire-pulse
wireplumber pavucontrol libpulse
```

### 📡 Bluetooth & Network
```
bluez bluez-utils network-manager-applet networkmanager
```

### 🖱️ Cursor
```
bibata-cursor-theme
```

### 🛠️ Utilities
```
wl-clip-persist wlogout nwg-look nwg-displays
starship fastfetch htop nano git wget
```

### 🎮 GPU (NVIDIA)
```
nvidia-open-dkms nvidia-settings libva-nvidia-driver
```

### 🌐 Apps
```
firefox google-chrome visual-studio-code-bin
pavucontrol dolphin
```

---

## 🎨 Theming
This rice uses a **custom One Dark-based palette** applied statically across all components:
- Waybar
- Swaync
- Rofi
- Hyprland borders
- Kitty terminal
- Wlogout

Colors are defined in `swaync/colors.css` and referenced across configs. To switch themes, swap the `colors-active.css` symlink in `~/.config/swaync/` to a different file in `themes-colors/`.

---

## ⌨️ Keybinds
| Keybind | Action |
|---|---|
| `Super + A` | Open app launcher (Rofi) |
| `Super + W` | Open wallpaper selector (Waypaper) |
| `Super + N` | Toggle notification center (Swaync) |
| `Super + T` | Open terminal (Kitty) |
| `Super + E` | Open file manager (Dolphin) |
| `Super + Shift + S` | Screenshot region |

---

## 🚀 Installation

1. Clone the repo:
```bash
git clone git@github.com:isleap9/isleap-dotfiles.git ~/dotfiles
```

2. Install packages (see above) with `yay`.

3. Copy configs:
```bash
cp -r ~/dotfiles/hypr ~/.config/
cp -r ~/dotfiles/waybar ~/.config/
cp -r ~/dotfiles/rofi ~/.config/
cp -r ~/dotfiles/swaync ~/.config/
cp -r ~/dotfiles/wlogout ~/.config/
```

4. Make wallpaper script executable:
```bash
chmod +x ~/.config/rofi/wallpaper-pick.sh
```

5. Log into Hyprland.

---

## 📁 Structure
```
dotfiles/
├── hypr/          # Hyprland config + keybinds + scripts
├── waybar/        # Waybar config + styles
├── rofi/          # Rofi launcher + themes
├── swaync/        # Swaync notification center + color themes
├── wlogout/       # Wlogout logout screen
```

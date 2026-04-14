# 🌸 isleap's dotfiles
A Hyprland rice with a dynamic theme switcher supporting multiple themes, centered island Waybar, and a clean minimal aesthetic.

---

## 📸 Preview
![Desktop](screenshots/1.png)
![Desktop2](screenshots/2.png)
![Desktop2](screenshots/3.png)
![Desktop2](screenshots/4.png)
![Desktop2](screenshots/5.png)
![Desktop2](screenshots/6.png)

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
| **Wallpaper** | awww |
| **Idle Daemon** | Hypridle |
| **Lock Screen** | Hyprlock (BlazinLock) |
| **Cursor** | Bibata-Modern-Ice |
| **GPU** | NVIDIA (nvidia-open-dkms) |

---

## 📦 Packages

### 🪟 Hyprland & WM
```
hyprland hypridle hyprlock polkit-gnome hyprshot
```

### 📊 Bar & Notifications
```
waybar swaync
```

### 🖼️ Wallpaper
```
awww
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
wl-clip-persist wlogout nwg-look nwg-displays brightnessctl
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

This rice uses a **dynamic theme switcher** that updates all components simultaneously:
- Waybar
- Swaync
- Rofi
- Hyprland borders
- Kitty terminal
- Wlogout
- Dolphin (via KDE color schemes)

### Available Themes

| Theme | Type |
|---|---|
| **One Dark** | Dark |
| **Catppuccin Mocha** | Dark |
| **Catppuccin Frappé** | Dark |
| **Catppuccin Latte** | Light |
| **Gruvbox Dark** | Dark |
| **Rosé Pine Moon** | Dark |
| **Rosé Pine Dawn** | Light |
| **Tokyo Night** | Dark |
| **Monokai Pro** | Dark |
| **Cyberdream** | Dark |
| **E-Ink** | Light |

Each app reads colors from a shared `active` symlink inside its own themes folder. Switching themes repoints all symlinks and reloads each app automatically.

---

## ⌨️ Keybinds
| Keybind | Action |
|---|---|
| `Super + A` | Open app launcher (Rofi) |
| `Super + Shift + W` | Open wallpaper selector (Rofi) |
| `Super + Shift + E` | Open global menu (Rofi) |
| `Super + N` | Toggle notification center (Swaync) |
| `Super + T` | Open terminal (Kitty) |
| `Super + E` | Open file manager (Dolphin) |
| `Super + L` | Lock screen (BlazinLock) |
| `Super + Shift + S` | Screenshot region |
| `Super + Shift + T` | Open theme switcher |

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
cp -r ~/dotfiles/kitty ~/.config/
cp -r ~/dotfiles/swaync ~/.config/
cp -r ~/dotfiles/wlogout ~/.config/
```

4. Copy KDE color schemes:
```bash
mkdir -p ~/.local/share/color-schemes
cp ~/dotfiles/color-schemes/*.colors ~/.local/share/color-schemes/
```

5. Create theme symlinks (defaults to One Dark):
```bash
ln -sf ~/.config/waybar/themes/onedark.css ~/.config/waybar/themes/active.css
ln -sf ~/.config/rofi/colors/isleaponedark.rasi ~/.config/rofi/colors/active.rasi
ln -sf ~/.config/swaync/themes-colors/onedark.css ~/.config/swaync/themes-colors/active.css
ln -sf ~/.config/kitty/themes/onedark.conf ~/.config/kitty/themes/active.conf
ln -sf ~/.config/wlogout/themes/onedark.css ~/.config/wlogout/style.css
ln -sf ~/.config/hypr/modules/themes/onedark.conf ~/.config/hypr/modules/active.conf
```

6. Make scripts executable:
```bash
chmod +x ~/.config/waybar/scripts/theme-switcher.sh
chmod +x ~/.config/waybar/scripts/launch.sh
chmod +x ~/.config/rofi/wallpaper-picker.sh
```

7. Log into Hyprland.

---

## 📁 Structure
```
dotfiles/
├── hypr/                        # Hyprland config + keybinds + modules
│   └── modules/
│       └── themes/              # Border color themes per theme
├── waybar/                      # Waybar config + styles
│   ├── themes/                  # Color themes (.css files)
│   └── scripts/                 # launch.sh, theme-switcher.sh, weather, etc.
├── rofi/                        # Rofi launcher + styles
│   └── colors/                  # Color themes (.rasi files)
├── kitty/                       # Kitty terminal config
│   └── themes/                  # Color themes (.conf files)
├── swaync/                      # Swaync notification center
│   └── themes-colors/           # Color themes (.css files)
├── wlogout/                     # Wlogout logout screen
│   └── themes/                  # Color themes (.css files)
└── color-schemes/               # KDE color schemes for Dolphin (.colors files)
```

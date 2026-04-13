# 🌸 isleap's dotfiles
A Hyprland rice with a dynamic theme switcher supporting One Dark and Catppuccin Mocha, centered island Waybar, and a clean minimal aesthetic.

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
| **Theming** | One Dark / Catppuccin Mocha (switchable) |
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

This rice uses a **dynamic theme switcher** that updates all components simultaneously:
- Waybar
- Swaync
- Rofi
- Hyprland borders
- Kitty terminal

Available themes: **One Dark** and **Catppuccin Mocha**

Each app reads colors from a shared `active` symlink inside its own themes folder. Switching themes repoints all symlinks and reloads each app automatically.

---

## ⌨️ Keybinds
| Keybind | Action |
|---|---|
| `Super + A` | Open app launcher (Rofi) |
| `Super + Shift + W` | Open wallpaper selector (Rofi) |
| `Super + N` | Toggle notification center (Swaync) |
| `Super + T` | Open terminal (Kitty) |
| `Super + E` | Open file manager (Dolphin) |
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

4. Create theme symlinks (defaults to One Dark):
```bash
ln -sf ~/.config/waybar/themes/onedark.css ~/.config/waybar/themes/active.css
ln -sf ~/.config/rofi/colors/isleaponedark.rasi ~/.config/rofi/colors/active.rasi
ln -sf ~/.config/swaync/themes-colors/onedark.css ~/.config/swaync/themes-colors/active.css
ln -sf ~/.config/kitty/themes/onedark.conf ~/.config/kitty/themes/active.conf
```

5. Make scripts executable:
```bash
chmod +x ~/.config/waybar/scripts/theme-switcher.sh
chmod +x ~/.config/rofi/wallpaper-pick.sh
```

6. Log into Hyprland.

---

## 📁 Structure
```
dotfiles/
├── hypr/                        # Hyprland config + keybinds + modules
│   └── modules/themes/          # Border color themes (onedark.conf, catppuccin-mocha.conf)
├── waybar/                      # Waybar config + styles
│   └── themes/                  # Color themes (onedark.css, catppuccin-mocha.css)
├── rofi/                        # Rofi launcher + styles
│   └── colors/                  # Color themes (.rasi files)
├── kitty/                       # Kitty terminal config
│   └── themes/                  # Color themes (onedark.conf, catppuccin-mocha.conf)
├── swaync/                      # Swaync notification center
│   └── themes-colors/           # Color themes (onedark.css, catppuccin-mocha.css)
└── wlogout/                     # Wlogout logout screen
```

# Graph Report - isleap-dotfiles  (2026-10-23)

## Corpus Check
- 8 files · ~24,039 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 176 nodes · 180 edges · 53 communities (10 shown, 43 thin omitted)
- Extraction: 84% EXTRACTED · 16% INFERRED · 0% AMBIGUOUS · INFERRED: 28 edges (avg confidence: 0.79)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Quickshell Desktop Surfaces
- Installer & NVIDIA Setup
- Hyprland Lua Modules
- Theme Switcher Variables
- Dolphin Sidebar Setup
- Theme & Color Pipeline
- Fastfetch ASCII Logos
- Dashboard & Weather
- Hyprlock Media Icon
- Hyprlock Avatar
- Blazin Music Scripts
- Quickshell Launch
- Wallpaper Picker
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 52

## God Nodes (most connected - your core abstractions)
1. `Quickshell Desktop Shell` - 17 edges
2. `Arch ASCII art (fastfetch logo)` - 7 edges
3. `install.sh script` - 7 edges
4. `Control Center` - 7 edges
5. `qs IPC Scripting Interface` - 7 edges
6. `Settings App` - 6 edges
7. `fastfetch ASCII art assets directory` - 5 edges
8. `main()` - 5 edges
9. `Bar (Five Layouts)` - 5 edges
10. `Dynamic Colors (Material You)` - 5 edges

## Surprising Connections (you probably didn't know these)
- `install.sh script` --calls--> `sddm-theme.sh script`  [EXTRACTED]
  install.sh → setup/sddm-theme.sh
- `Arch ASCII art (fastfetch logo)` --implements--> `ASCII art as text-based image medium`  [INFERRED]
  fastfetch/ascii/arch.txt → fastfetch/ascii/cat.txt
- `Rose ASCII art (fastfetch logo)` --implements--> `ASCII art as text-based image medium`  [INFERRED]
  fastfetch/ascii/rose.txt → fastfetch/ascii/cat.txt
- `Triangle ASCII art (fastfetch logo)` --implements--> `ASCII art as text-based image medium`  [INFERRED]
  fastfetch/ascii/triangle.txt → fastfetch/ascii/cat.txt
- `Cat ASCII art (fastfetch logo)` --conceptually_related_to--> `fastfetch ASCII art assets directory`  [EXTRACTED]
  fastfetch/ascii/cat.txt → fastfetch/ascii/arch.txt

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Interchangeable fastfetch logo choices** — config_fastfetch_ascii_arch_ascii_art, config_fastfetch_ascii_cat_ascii_art, config_fastfetch_ascii_rose_ascii_art, config_fastfetch_ascii_triangle_ascii_art [EXTRACTED 1.00]
- **Quickshell Desktop Surface Family** — readme_quickshell_desktop, readme_bar, readme_app_launcher, readme_notifications, readme_power_menu, readme_dashboard, readme_quick_settings, readme_control_center, readme_settings_app, readme_workspace_overview [EXTRACTED 1.00]
- **Theme and Dynamic Color Flow** — readme_static_themes, readme_dynamic_colors, readme_matugen, readme_active_symlink_mechanism, readme_wallpaper_color_pipeline, readme_theme_qml, readme_waybar_themes_dir [EXTRACTED 1.00]
- **Installer Bootstrap Flow** — install, readme_nvidia_open_driver, readme_qs_wallpaper_picker, readme_qylock, readme_sddm_login, setup_dolphin_places [EXTRACTED 1.00]

## Communities (53 total, 43 thin omitted)

### Community 0 - "Quickshell Desktop Surfaces"
Cohesion: 0.12
Nodes (24): App Launcher, Bar (Five Layouts), Bar Widgets, Capture Menu (Screenshot/Recording), Clipboard History (cliphist), quickshell/config.json, Config.qml, Control Center (+16 more)

### Community 1 - "Installer & NVIDIA Setup"
Cohesion: 0.17
Nodes (14): ask(), die(), note(), install.sh script, step(), warn(), arch-update, NVIDIA Open Kernel Modules (+6 more)

### Community 3 - "Theme Switcher Variables"
Cohesion: 0.15
Nodes (12): BTOP_THEME, CAL_DAYS, CAL_MONTHS, CAL_WEEKDAYS, CAVA_COLOR, HYPR_ACTIVE_BORDER, HYPR_INACTIVE_BORDER, HYPR_THEME (+4 more)

### Community 4 - "Dolphin Sidebar Setup"
Cohesion: 0.31
Nodes (3): Dolphin File Manager Setup, Open With Menu Fix, main()

### Community 5 - "Theme & Color Pipeline"
Cohesion: 0.24
Nodes (8): Dynamic Colors (Material You), matugen, config/matugen Templates, qs-wallpaper-picker, Static Themes (24 Hand-Made), Theme.qml, waybar/theme-switcher.sh, waybar/themes Directory (legacy)

### Community 6 - "Fastfetch ASCII Logos"
Cohesion: 0.50
Nodes (8): Arch ASCII art (fastfetch logo), Arch Linux (distribution represented by Arch logo), ASCII art as text-based image medium, Cat ASCII art (fastfetch logo), fastfetch ASCII art assets directory, fastfetch (system-info CLI tool), Rose ASCII art (fastfetch logo), Triangle ASCII art (fastfetch logo)

### Community 8 - "Dashboard & Weather"
Cohesion: 0.40
Nodes (5): DankMaterialShell (inspiration), Dashboard, Night Light (hyprsunset), Weather Data (Open-Meteo), waybar/weather.py

### Community 9 - "Hyprlock Media Icon"
Cohesion: 0.83
Nodes (4): Hyprlock Lock Screen, Media Playback Indicator UI Element, Music Icon Asset (music.webp), White Eighth-Note (Beamed) Glyph

### Community 10 - "Hyprlock Avatar"
Cohesion: 0.67
Nodes (4): hyprlock profile picture asset (pfp.jpg), Anime-style avatar artwork (pink-purple female character portrait), Hyprlock lock-screen avatar display element, Pink/purple color theme

### Community 11 - "Blazin Music Scripts"
Cohesion: 1.00
Nodes (3): get_metadata(), get_source_info(), blazinscripts.sh script

## Knowledge Gaps
- **28 isolated node(s):** `BTOP_THEME`, `CAL_DAYS`, `CAL_MONTHS`, `CAL_WEEKDAYS`, `CAVA_COLOR` (+23 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 96 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **43 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Quickshell Desktop Shell` connect `Quickshell Desktop Surfaces` to `Dashboard & Weather`, `Installer & NVIDIA Setup`?**
  _High betweenness centrality (0.073) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Arch ASCII art (fastfetch logo)` (e.g. with `Arch Linux (distribution represented by Arch logo)` and `ASCII art as text-based image medium`) actually correct?**
  _`Arch ASCII art (fastfetch logo)` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `BTOP_THEME`, `CAL_DAYS`, `CAL_MONTHS` to the rest of the system?**
  _28 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Quickshell Desktop Surfaces` be split into smaller, more focused modules?**
  _Cohesion score 0.12318840579710146 - nodes in this community are weakly interconnected._
- **Why does `Settings App` connect `Quickshell Desktop Surfaces` to `Hyprland Lua Modules`, `Theme & Color Pipeline`?**
  _High betweenness centrality (0.047) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Control Center` (e.g. with `waybar/theme-switcher.sh` and `Quick Settings`) actually correct?**
  _`Control Center` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Should `Hyprland Lua Modules` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
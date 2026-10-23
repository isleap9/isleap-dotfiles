# Graph Report - config  (2026-10-23)

## Corpus Check
- Corpus is ~19,234 words - fits in a single context window. You may not need a graph.

## Summary
- 104 nodes · 73 edges · 45 communities (5 shown, 40 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Theme Switcher
- Fastfetch ASCII Logos
- Hyprlock Media Icon
- Hyprlock Avatar
- Blazin Music Scripts
- Quickshell Launch
- Wallpaper Picker
- KDE Color Apply
- Color Picker
- Spotify Notify
- Wallpaper Dynamic
- Files Open-With
- Files Paste
- Screen Lock
- Papirus Accent
- Wallpaper Setter
- Wallpaper Hook

## God Nodes (most connected - your core abstractions)
1. `Arch ASCII art (fastfetch logo)` - 7 edges
2. `fastfetch ASCII art assets directory` - 5 edges
3. `ASCII art as text-based image medium` - 4 edges
4. `blazinscripts.sh script` - 3 edges
5. `get_metadata()` - 3 edges
6. `get_source_info()` - 3 edges
7. `Cat ASCII art (fastfetch logo)` - 3 edges
8. `Rose ASCII art (fastfetch logo)` - 3 edges
9. `Triangle ASCII art (fastfetch logo)` - 3 edges
10. `Music Icon Asset (music.webp)` - 3 edges

## Surprising Connections (you probably didn't know these)
- `Arch ASCII art (fastfetch logo)` --implements--> `ASCII art as text-based image medium`  [INFERRED]
  fastfetch/ascii/arch.txt → fastfetch/ascii/cat.txt
- `Rose ASCII art (fastfetch logo)` --implements--> `ASCII art as text-based image medium`  [INFERRED]
  fastfetch/ascii/rose.txt → fastfetch/ascii/cat.txt
- `Triangle ASCII art (fastfetch logo)` --implements--> `ASCII art as text-based image medium`  [INFERRED]
  fastfetch/ascii/triangle.txt → fastfetch/ascii/cat.txt
- `Cat ASCII art (fastfetch logo)` --semantically_similar_to--> `Arch ASCII art (fastfetch logo)`  [EXTRACTED] [semantically similar]
  fastfetch/ascii/cat.txt → fastfetch/ascii/arch.txt
- `Rose ASCII art (fastfetch logo)` --semantically_similar_to--> `Arch ASCII art (fastfetch logo)`  [EXTRACTED] [semantically similar]
  fastfetch/ascii/rose.txt → fastfetch/ascii/arch.txt

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Interchangeable fastfetch logo choices** — config_fastfetch_ascii_arch_ascii_art, config_fastfetch_ascii_cat_ascii_art, config_fastfetch_ascii_rose_ascii_art, config_fastfetch_ascii_triangle_ascii_art [EXTRACTED 1.00]

## Communities (45 total, 40 thin omitted)

### Community 1 - "Theme Switcher"
Cohesion: 0.15
Nodes (12): BTOP_THEME, CAL_DAYS, CAL_MONTHS, CAL_WEEKDAYS, CAVA_COLOR, HYPR_ACTIVE_BORDER, HYPR_INACTIVE_BORDER, HYPR_THEME (+4 more)

### Community 2 - "Fastfetch ASCII Logos"
Cohesion: 0.50
Nodes (8): Arch ASCII art (fastfetch logo), Arch Linux (distribution represented by Arch logo), ASCII art as text-based image medium, Cat ASCII art (fastfetch logo), fastfetch ASCII art assets directory, fastfetch (system-info CLI tool), Rose ASCII art (fastfetch logo), Triangle ASCII art (fastfetch logo)

### Community 4 - "Hyprlock Media Icon"
Cohesion: 0.83
Nodes (4): Hyprlock Lock Screen, Media Playback Indicator UI Element, Music Icon Asset (music.webp), White Eighth-Note (Beamed) Glyph

### Community 5 - "Hyprlock Avatar"
Cohesion: 0.67
Nodes (4): hyprlock profile picture asset (pfp.jpg), Anime-style avatar artwork (pink-purple female character portrait), Hyprlock lock-screen avatar display element, Pink/purple color theme

### Community 6 - "Blazin Music Scripts"
Cohesion: 1.00
Nodes (3): get_metadata(), get_source_info(), blazinscripts.sh script

## Knowledge Gaps
- **13 isolated node(s):** `QS_WALLPAPER_DIR`, `WAYBAR_THEME`, `KITTY_THEME`, `KDE_THEME`, `HYPR_THEME` (+8 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 78 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **40 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Are the 3 inferred relationships involving `Arch ASCII art (fastfetch logo)` (e.g. with `Arch Linux (distribution represented by Arch logo)` and `ASCII art as text-based image medium`) actually correct?**
  _`Arch ASCII art (fastfetch logo)` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `QS_WALLPAPER_DIR`, `WAYBAR_THEME`, `KITTY_THEME` to the rest of the system?**
  _13 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Are the 4 inferred relationships involving `ASCII art as text-based image medium` (e.g. with `Arch ASCII art (fastfetch logo)` and `Cat ASCII art (fastfetch logo)`) actually correct?**
  _`ASCII art as text-based image medium` has 4 INFERRED edges - model-reasoned connections that need verification._
import QtQuick
import qs

// Keyboard shortcuts (keep in sync with ~/.config/hypr/modules/binds.lua)
MenuList {
    id: root

    property var cc   // set by the loader

    placeholder: "Search shortcuts…"
    rowHeight: 44
    items: [
        ["󰆍", "SUPER + T", "Terminal"],
        ["󰅙", "SUPER + Q", "Close window"],
        ["󰖟", "SUPER + B", "Browser"],
        ["󰨞", "SUPER + C", "VS Code"],
        ["󰉋", "SUPER + E", "Files"],
        ["󰀻", "SUPER + SPACE", "App launcher"],
        ["󰐥", "SUPER + M", "Power menu"],
        ["󰂚", "SUPER + N", "Notifications"],
        ["󰌾", "SUPER + SHIFT + L", "Lock screen"],
        ["󰉯", "SUPER + W", "Toggle floating"],
        ["󰍹", "SUPER + F", "Maximize"],
        ["󰊓", "SUPER + SHIFT + F", "Fullscreen"],
        ["󰖲", "SUPER + S", "Scratchpad"],
        ["󰒅", "SUPER + R", "Restart Quickshell"],
        ["󰒓", "SUPER + ALT + SPACE", "Control center"],
        ["󰧨", "SUPER + SHIFT + T", "Theme switcher"],
        ["󰸉", "SUPER + SHIFT + W", "Wallpaper picker"],
        ["󰅍", "SUPER + SHIFT + C", "Clipboard"],
        ["󰄀", "SUPER + SHIFT + V", "Capture menu"],
        ["󰹑", "SUPER + SHIFT + S", "Screenshot region"],
        ["󰃉", "SUPER + SHIFT + P", "Color picker"],
        ["󰞅", "SUPER + PERIOD", "Emoji"],
        ["󰒭", "SUPER + J/L/I/K", "Move focus"],
        ["󰒭", "SUPER + 1-0", "Switch workspace"],
        ["󰒭", "SUPER + SHIFT + 1-0", "Move window to workspace"],
        ["󰍽", "SUPER + scroll", "Cycle workspaces"]
    ].map(([icon, keys, what]) => ({ icon, label: what, sub: keys }))

    onBack: cc?.go("main")
}

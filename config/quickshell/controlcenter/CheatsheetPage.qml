import QtQuick
import qs

// Keyboard shortcuts (keep in sync with ~/.config/hypr/modules/binds.lua)
MenuList {
    id: root

    property var cc   // set by the loader

    placeholder: "Search shortcuts…"
    rowHeight: 44
    items: [
        ["terminal", "SUPER + T", "Terminal"],
        ["cancel", "SUPER + Q", "Close window"],
        ["language", "SUPER + B", "Browser"],
        ["code", "SUPER + C", "VS Code"],
        ["folder", "SUPER + E", "Files"],
        ["apps", "SUPER + SPACE", "App launcher"],
        ["power_settings_new", "SUPER + M", "Power menu"],
        ["notifications", "SUPER + N", "Notifications"],
        ["lock", "SUPER + SHIFT + L", "Lock screen"],
        ["picture_in_picture", "SUPER + W", "Toggle floating"],
        ["monitor", "SUPER + F", "Maximize"],
        ["fullscreen", "SUPER + SHIFT + F", "Fullscreen"],
        ["select_window", "SUPER + S", "Scratchpad"],
        ["restart_alt", "SUPER + R", "Restart Quickshell"],
        ["settings", "SUPER + ALT + SPACE", "Control center"],
        ["palette", "SUPER + SHIFT + T", "Theme switcher"],
        ["wallpaper", "SUPER + SHIFT + W", "Wallpaper picker"],
        ["content_paste", "SUPER + SHIFT + C", "Clipboard"],
        ["photo_camera", "SUPER + SHIFT + V", "Capture menu"],
        ["screenshot_monitor", "SUPER + SHIFT + S", "Screenshot region"],
        ["colorize", "SUPER + SHIFT + P", "Color picker"],
        ["mood", "SUPER + PERIOD", "Emoji"],
        ["skip_next", "SUPER + J/L/I/K", "Move focus"],
        ["skip_next", "SUPER + 1-0", "Switch workspace"],
        ["skip_next", "SUPER + SHIFT + 1-0", "Move window to workspace"],
        ["mouse", "SUPER + scroll", "Cycle workspaces"]
    ].map(([icon, keys, what]) => ({ icon, label: what, sub: keys }))

    onBack: cc?.go("main")
}

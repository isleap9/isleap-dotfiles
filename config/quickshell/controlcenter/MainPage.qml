import QtQuick
import qs

// Home page of the control center
MenuList {
    id: root

    property var cc   // the ControlCenter window (set by the loader)

    placeholder: "Search options…"
    items: [
        { icon: "\u{F0C7B}", label: "Bar Layout", sub: "Default, Default 2, Minimal, Sleek", page: "barlayout" },
        { icon: "󰧨", label: "Theme Switcher", sub: "Pick a color theme", page: "themes" },
        { icon: "󰔎", label: "Dynamic Theme", sub: "Colors from your wallpaper", page: "dynamic" },
        { icon: "󰸉", label: "Wallpaper", sub: "Open the wallpaper picker", run: "~/.config/quickshell/scripts/wallpaper-picker.sh" },
        { icon: "󰅍", label: "Clipboard", sub: "History and favorites", page: "clipboard" },
        { icon: "󰄀", label: "Capture", sub: "Screenshots and color picker", page: "capture" },
        { icon: "󰞅", label: "Emoji", sub: "Search and copy emoji", page: "emoji" },
        { icon: "󰌌", label: "Cheatsheet", sub: "Keyboard shortcuts", page: "cheatsheet" },
        { icon: "\u{F0493}", label: "Settings", sub: "Bar, fonts, notifications and more", settings: true }
    ]

    onActivated: item => item.settings ? Globals.openSettings("") : item.page ? cc.go(item.page) : cc.runAndClose(item.run)
    onBack: Globals.controlCenterOpen = false
}

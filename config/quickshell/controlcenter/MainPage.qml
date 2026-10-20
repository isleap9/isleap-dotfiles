import QtQuick
import qs

// Home page of the control center
MenuList {
    id: root

    property var cc   // the ControlCenter window (set by the loader)

    placeholder: "Search options…"
    items: [
        { icon: "toolbar", label: "Bar Layout", sub: "Default, Default 2, Minimal, Sleek", page: "barlayout" },
        { icon: "palette", label: "Theme Switcher", sub: "Pick a color theme", page: "themes" },
        { icon: "contrast", label: "Dynamic Theme", sub: "Colors from your wallpaper", page: "dynamic" },
        { icon: "wallpaper", label: "Wallpaper", sub: "Open the wallpaper picker", run: "~/.config/quickshell/scripts/wallpaper-picker.sh" },
        { icon: "content_paste", label: "Clipboard", sub: "History and favorites", page: "clipboard" },
        { icon: "photo_camera", label: "Capture", sub: "Screenshots and color picker", page: "capture" },
        { icon: "mood", label: "Emoji", sub: "Search and copy emoji", page: "emoji" },
        { icon: "keyboard", label: "Cheatsheet", sub: "Keyboard shortcuts", page: "cheatsheet" },
        { icon: "settings", label: "Settings", sub: "Bar, fonts, notifications and more", settings: true }
    ]

    onActivated: item => item.settings ? Globals.openSettings("") : item.page ? cc.go(item.page) : cc.runAndClose(item.run)
    onBack: Globals.controlCenterOpen = false
}

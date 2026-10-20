import QtQuick
import qs

// Screenshots (hyprshot) and the color picker
MenuList {
    id: root

    property var cc   // set by the loader

    readonly property string out: "--output-folder ~/Pictures/Screenshots"

    placeholder: "Search…"
    items: [
        { icon: "screenshot_monitor", label: "Region", sub: "Select an area", run: `hyprshot -m region ${out}` },
        { icon: "monitor", label: "Fullscreen", sub: "Active monitor", run: `hyprshot -m output -m active ${out}` },
        { icon: "fit_screen", label: "Window", sub: "Click a window", run: `hyprshot -m window ${out}` },
        { icon: "colorize", label: "Color picker", sub: "Copy a color from the screen", run: "~/.config/hypr/scripts/color-picker.sh" }
    ]

    // Small delay so the control center is gone before the capture starts
    onActivated: item => cc.runAndClose("sleep 0.3; " + item.run)
    onBack: cc?.go("main")
}

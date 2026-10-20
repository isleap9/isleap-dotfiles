import QtQuick
import qs

// Pick the bar layout (replaces the old "Waybar Layout" rofi menu)
MenuList {
    id: root

    property var cc   // set by the loader

    placeholder: "Search layouts…"
    items: [
        { icon: "\u{F0C7B}", label: "Default", sub: "Separate pills, cava visualizer", id: "default" },
        { icon: "\u{F0C7B}", label: "Default 2", sub: "Grouped right side, classic workspaces", id: "default2" },
        { icon: "\u{F0C7B}", label: "Minimal", sub: "Everything in one centered pill", id: "minimal" },
        { icon: "\u{F0C7B}", label: "Sleek", sub: "Solid bar attached to the top edge", id: "sleek" },
        { icon: "\u{F03EB}", label: "Custom", sub: "Your own bar — edit it in Settings → Bar", id: "custom" }
    ].map(i => Object.assign(i, { checked: i.id === BarConfig.layout }))

    onActivated: item => BarConfig.set(item.id)
    onBack: cc?.go("main")
}

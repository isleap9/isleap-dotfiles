import QtQuick
import qs

// Pick the bar layout (replaces the old "Waybar Layout" rofi menu)
MenuList {
    id: root

    property var cc   // set by the loader

    placeholder: "Search layouts…"
    items: [
        { icon: "toolbar", label: "Default", sub: "Separate pills, cava visualizer", id: "default" },
        { icon: "toolbar", label: "Default 2", sub: "Grouped right side, classic workspaces", id: "default2" },
        { icon: "toolbar", label: "Minimal", sub: "Everything in one centered pill", id: "minimal" },
        { icon: "toolbar", label: "Sleek", sub: "Solid bar attached to the top edge", id: "sleek" },
        { icon: "edit", label: "Custom", sub: "Your own bar — edit it in Settings → Bar", id: "custom" }
    ].map(i => Object.assign(i, { checked: i.id === BarConfig.layout }))

    onActivated: item => BarConfig.set(item.id)
    onBack: cc?.go("main")
}

import QtQuick
import qs

// All themes from the theme switcher, with color swatches. Stays open so you can try several.
MenuList {
    id: root

    property var cc   // set by the loader

    placeholder: "Search themes…"
    emptyText: "Loading themes…"
    items: Themes.list.map(t => ({
        icon: "󰏘",
        label: t.name,
        key: t.key,
        swatches: t.colors,
        checked: t.file === Themes.current
    }))

    onActivated: item => Themes.apply(item.key)
    onBack: cc?.go("main")

    Component.onCompleted: Themes.refresh()
}

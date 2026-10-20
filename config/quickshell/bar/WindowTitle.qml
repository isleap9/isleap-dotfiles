import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components

// The focused window: app icon + title
Pill {
    id: root

    readonly property var win: ToplevelManager.activeToplevel
    readonly property int maxWidth: BarConfig.opt(settings, "maxWidth") ?? 300
    readonly property var entry: win ? DesktopEntries.heuristicLookup(win.appId) : null

    shown: win !== null && (win.title ?? "") !== ""
    interactive: false

    IconImage {
        visible: BarConfig.opt(root.settings, "icon") !== false
        Layout.alignment: Qt.AlignVCenter
        implicitSize: BarConfig.iconSize + 2
        source: Globals.appIcon(root.win?.appId)
    }
    BarText {
        Layout.maximumWidth: root.maxWidth
        elide: Text.ElideRight
        text: BarConfig.opt(root.settings, "show") === "app" ? (root.entry?.name ?? root.win?.appId ?? "") : (root.win?.title ?? "")
    }
}

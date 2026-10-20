import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Popups in the top-right corner of the focused monitor
PanelWindow {
    id: win

    screen: Globals.focusedScreen
    visible: Notifs.popups.length > 0 && !Globals.notifCenterOpen

    // Corner from Settings → Notifications
    readonly property string pos: Config.notifications.position
    anchors.top: pos.startsWith("top")
    anchors.bottom: pos.startsWith("bottom")
    anchors.left: pos.endsWith("left")
    anchors.right: pos.endsWith("right")
    margins.top: 8
    margins.bottom: 16
    margins.left: Theme.barSideMargin
    margins.right: Theme.barSideMargin
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"

    Column {
        id: column
        width: parent.width
        spacing: 10

        Repeater {
            model: Notifs.popups.slice(0, Config.notifications.maxPopups)

            NotificationCard {
                required property var modelData
                notif: modelData
                popup: true
                width: column.width
            }
        }
    }
}

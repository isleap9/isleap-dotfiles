import QtQuick
import qs
import qs.components

// Notifications: click opens the center, right click toggles Do Not Disturb
Pill {
    shown: Config.bar.modules.notifications
    onClicked: m => m.button === Qt.RightButton
        ? Notifs.dnd = !Notifs.dnd
        : Globals.notifCenterOpen = !Globals.notifCenterOpen
    BarText {
        icon: true
        text: Notifs.dnd ? "󰂛" : Notifs.count > 0 ? "󱅫" : "󰂚"
    }
}

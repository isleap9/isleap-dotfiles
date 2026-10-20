import QtQuick
import qs
import qs.components

// Notifications (Material): a bell with an accent badge counting unread ones.
// Click: the notification center. Right click: Do Not Disturb.
Pill {
    id: root
    onClicked: m => m.button === Qt.RightButton
        ? Notifs.dnd = !Notifs.dnd
        : Globals.notifCenterOpen = !Globals.notifCenterOpen

    Item {
        implicitWidth: bell.implicitWidth
        implicitHeight: bell.implicitHeight
        BarText {
            id: bell
            icon: true
            text: Notifs.dnd ? "notifications_off" : "notifications"
            color: Notifs.dnd ? Theme.fg2 : root.iconColor
        }
        Rectangle {
            visible: Notifs.count > 0 && !Notifs.dnd
            x: bell.width - width / 2 - 1
            y: -height / 3
            width: Math.max(height, badge.implicitWidth + 8)
            height: 15
            radius: height / 2
            color: BarConfig.accentColor
            // Outline in the bar color, so the badge stands out even on light accents
            border.width: 2
            border.color: BarConfig.solid ? BarConfig.solidColor : BarConfig.pillColor
            Text {
                id: badge
                anchors.centerIn: parent
                text: Notifs.count > 99 ? "99+" : Notifs.count
                color: Theme.bg0
                font.family: Theme.font
                font.pixelSize: 10
                font.weight: Font.Black
            }
        }
    }
}

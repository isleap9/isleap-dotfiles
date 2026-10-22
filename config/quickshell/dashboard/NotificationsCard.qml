import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.notifications

// Recent notifications, with Do Not Disturb and Clear all
DashCard {
    id: card

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: "notifications"
                color: Theme.accent
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxes
                font.pixelSize: Theme.fontSize + 2
            }
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: Notifs.count > 0 ? `Notifications · ${Notifs.count}` : "Notifications"
                elide: Text.ElideRight
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }
            DashButton {
                icon: Notifs.dnd ? "notifications_off" : "notifications"
                active: Notifs.dnd
                size: 32
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            DashButton {
                icon: "delete"
                size: 32
                enabled: Notifs.count > 0
                onClicked: Notifs.clearAll()
            }
        }

        ListView {
            SmoothWheel { flick: list }
            MScrollBar { flick: list }
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: [...Notifs.list].reverse()
            boundsBehavior: Flickable.StopAtBounds

            delegate: NotificationCard {
                required property var modelData
                notif: modelData
                width: list.width - (list.contentHeight > list.height ? 12 : 0)
            }

            Column {
                visible: Notifs.count === 0
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Notifs.dnd ? "notifications_off" : "done_all"
                    color: Theme.bg4
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: 44
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Notifs.dnd ? "Do not disturb is on" : "All caught up"
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: Font.Bold
                }
            }
        }
    }
}

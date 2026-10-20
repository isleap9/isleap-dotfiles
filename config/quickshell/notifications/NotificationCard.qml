import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs

// One notification. Used both for popups and in the notification center.
Rectangle {
    id: card

    required property Notification notif
    property bool popup: false

    readonly property string icon: Notifs.iconFor(notif)
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 28
    radius: 18
    color: Theme.bg1
    border.width: critical ? 2 : 1
    border.color: critical ? Theme.red : Theme.bg3

    // Popups go away after a while (they stay in the center)
    Timer {
        running: card.popup && !card.critical && !hover.containsMouse
        interval: card.notif?.expireTimeout > 0 ? card.notif.expireTimeout : Config.notifications.timeout * 1000
        onTriggered: Notifs.removePopup(card.notif)
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => {
            if (m.button === Qt.MiddleButton) { card.notif.dismiss(); return; }
            const def = card.notif.actions.find(a => a.identifier === "default");
            if (def) def.invoke();
            else if (card.popup) Notifs.removePopup(card.notif);
        }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        IconImage {
            Layout.alignment: Qt.AlignTop
            visible: card.icon !== ""
            implicitSize: 44
            source: card.icon
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 3

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: card.notif?.appName ?? ""
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }

                // Close button
                Text {
                    text: "󰅖"
                    color: closeArea.containsMouse ? Theme.red : Theme.fg2
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.fontSize + 1
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.notif.dismiss()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.notif?.summary ?? ""
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Black
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notif?.body ?? ""
                textFormat: Text.StyledText
                color: Theme.fg1
                opacity: 0.85
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 4 : 8
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            // Action buttons (skip the hidden "default" action)
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: actions.count > 0
                spacing: 6

                Repeater {
                    id: actions
                    model: (card.notif?.actions ?? []).filter(a => a.identifier !== "default")

                    Rectangle {
                        required property NotificationAction modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 15
                        color: actArea.containsMouse ? Theme.bg3 : Theme.bg2

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            id: actArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}

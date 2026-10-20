import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs

// Side panel with all notifications (SUPER+N). Esc or click outside closes.
LazyLoader {
    active: Globals.notifCenterOpen

    PanelWindow {
        id: win

        screen: Globals.popupScreen
        anchors { top: true; right: true; bottom: true }
        margins { top: 8; right: Theme.barSideMargin; bottom: 16 }
        exclusiveZone: 0
        implicitWidth: 420
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell-notification-center"

        HyprlandFocusGrab {
            active: true
            windows: [win]
            onCleared: Globals.notifCenterOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Theme.bg0
            border.color: Theme.bg3
            border.width: 1
            focus: true
            Keys.onEscapePressed: Globals.notifCenterOpen = false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header: title, DND toggle, clear all
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 5
                        font.weight: Font.Black
                    }

                    HeaderButton {
                        icon: Notifs.dnd ? "󰂛" : "󰂚"
                        label: "DND"
                        active: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                    HeaderButton {
                        icon: "󰎟"
                        label: "Clear"
                        onClicked: Notifs.clearAll()
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: Notifs.list

                    delegate: NotificationCard {
                        required property var modelData
                        notif: modelData
                        width: ListView.view.width
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: Notifs.count === 0
                        text: "󰂚\nNo notifications"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 2
                    }
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: btn
        property string icon
        property string label
        property bool active: false
        signal clicked

        implicitHeight: 32
        implicitWidth: row.implicitWidth + 24
        radius: 16
        color: active ? Theme.accent : area.containsMouse ? Theme.bg3 : Theme.bg2

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: btn.icon
                color: btn.active ? Theme.bg1 : Theme.fg1
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontSize + 1
            }
            Text {
                text: btn.label
                color: btn.active ? Theme.bg1 : Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Bold
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}

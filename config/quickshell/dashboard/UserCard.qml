import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs

// You, this computer, how long it's been on, and quick buttons
DashCard {
    id: card

    readonly property string user: Quickshell.env("USER")
    property string host: ""

    Process {
        running: true
        command: ["cat", "/proc/sys/kernel/hostname"]
        stdout: StdioCollector { onStreamFinished: card.host = text.trim() }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ClippingRectangle {
            Layout.preferredWidth: Math.min(card.height - 2 * card.pad, 64)
            Layout.preferredHeight: Layout.preferredWidth
            radius: width / 2
            color: Theme.accent
            Text {
                visible: avatar.status !== Image.Ready
                anchors.centerIn: parent
                text: card.user.charAt(0).toUpperCase()
                color: Theme.bg0
                font.family: Theme.font
                font.pixelSize: parent.width * 0.5
                font.weight: Font.Black
            }
            Image {
                id: avatar
                anchors.fill: parent
                source: Avatar.source
                cache: false
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            // Hover: click to change (right-click removes it)
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                visible: faceArea.containsMouse
                Text {
                    anchors.centerIn: parent
                    text: "photo_camera"
                    color: "white"
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: parent.width * 0.4
                }
            }
            MouseArea {
                id: faceArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => m.button === Qt.RightButton ? Avatar.remove() : Avatar.pick()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: card.user
                elide: Text.ElideRight
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                text: `${card.host} · up ${SysStats.duration(SysStats.uptime)}`
                elide: Text.ElideRight
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }

        RowLayout {
            visible: card.width >= 300
            spacing: 2
            DashButton { icon: "settings"; onClicked: { Globals.dashboardOpen = false; Globals.openSettings(""); } }
            DashButton {
                icon: "lock"
                onClicked: { Globals.dashboardOpen = false; Globals.run(Quickshell.env("HOME") + "/.config/quickshell/scripts/lock.sh"); }
            }
            DashButton { icon: "power_settings_new"; onClicked: { Globals.closeAll(); Globals.powerMenuOpen = true; } }
        }
    }
}

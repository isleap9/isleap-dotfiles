import QtQuick
import QtQuick.Layouts
import qs

// Pick one of a few options. options: [[value, label], …]
Rectangle {
    id: root

    property var options: []
    property var current
    signal selected(var value)

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 34
    radius: 17
    color: Theme.bg2

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options
            Rectangle {
                id: opt
                required property var modelData
                readonly property bool active: modelData[0] === root.current
                implicitWidth: label.implicitWidth + 24
                implicitHeight: 28
                radius: 14
                color: active ? Theme.accent : area.containsMouse ? Theme.bg3 : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: opt.modelData[1]
                    color: opt.active ? Theme.bg1 : Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(opt.modelData[0])
                }
            }
        }
    }
}

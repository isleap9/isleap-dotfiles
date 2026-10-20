import QtQuick
import QtQuick.Layouts
import qs

// Pill button with an optional icon
Rectangle {
    id: root

    property string text
    property string icon: ""
    property bool primary: false
    property bool danger: false
    signal clicked

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 34
    radius: 17
    color: danger ? Theme.red : primary ? Theme.accent : area.containsMouse ? Theme.bg3 : Theme.bg2

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.primary || root.danger ? Theme.bg1 : Theme.fg1
            font.family: Theme.iconFont
            font.variableAxes: Theme.iconAxes
            font.pixelSize: Theme.fontSize + 1
        }
        Text {
            text: root.text
            color: root.primary || root.danger ? Theme.bg1 : Theme.fg1
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
        onClicked: root.clicked()
    }
}

import QtQuick
import qs

// Small round icon button (move up/down, settings, remove…)
Rectangle {
    id: root

    property string icon
    property string tip: ""
    property bool active: false
    property bool danger: false
    signal clicked

    implicitWidth: 30
    implicitHeight: 30
    radius: 15
    opacity: enabled ? 1 : 0.3
    color: active ? Theme.accent
         : area.containsMouse && enabled ? (danger ? Theme.red : Theme.bg3)
         : "transparent"

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active || (area.containsMouse && root.danger) ? Theme.bg1 : Theme.fg1
        font.family: Theme.iconFont
        font.variableAxes: Theme.iconAxes
        font.pixelSize: Theme.fontSize + 1
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }
}

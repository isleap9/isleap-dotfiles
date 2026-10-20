import QtQuick
import qs

// Material 3 switch: outlined track when off, filled with a check when on.
// Bind `checked`, handle `toggled`.
Rectangle {
    id: root

    property bool checked: false
    signal toggled

    implicitWidth: 52
    implicitHeight: 32
    radius: 16
    color: checked ? Theme.accent : Theme.bg3
    border.width: checked ? 0 : 2
    border.color: Theme.fg2
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        readonly property int d: root.checked ? 24 : area.pressed ? 26 : 16
        width: d; height: d; radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 8 - (d - 16) / 2
        color: root.checked ? Theme.bg0 : Theme.fg2
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            visible: root.checked
            text: "check"
            color: Theme.accent
            font.family: Theme.iconFont
            font.variableAxes: Theme.iconAxes
            font.pixelSize: 15
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}

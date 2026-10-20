import QtQuick
import qs

// On/off switch. It doesn't change itself: bind `checked` and handle `toggled`.
Rectangle {
    id: root

    property bool checked: false
    signal toggled

    implicitWidth: 52
    implicitHeight: 30
    radius: height / 2
    color: checked ? Theme.accent : Theme.bg3
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: 22; height: 22; radius: 11
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? Theme.bg1 : Theme.fg2
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}

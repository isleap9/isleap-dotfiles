import QtQuick
import qs

// Round icon button. filled = accent background (e.g. play/pause)
Rectangle {
    id: root

    property string icon
    property bool filled: false
    property bool active: false          // highlighted (e.g. shuffle on)
    property int size: 36
    property real iconScale: 0.5
    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    opacity: enabled ? 1 : 0.35
    color: filled ? (area.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
        : active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
        : area.containsMouse ? Theme.bg3 : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }
    scale: area.pressed ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.filled ? Theme.bg0 : root.active ? Theme.accent : Theme.fg1
        font.family: Theme.iconFont
        font.pixelSize: Math.round(root.size * root.iconScale)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }
}

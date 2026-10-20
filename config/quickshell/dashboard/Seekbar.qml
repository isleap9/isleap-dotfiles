import QtQuick
import qs

// Horizontal slider (0–1). Click or drag to change; emits moved(value) when released.
Item {
    id: root

    property real value: 0
    property bool interactive: true
    property color color: Theme.accent
    property int thickness: 6
    signal moved(real value)

    readonly property real shown: area.pressed ? area.dragValue : Math.max(0, Math.min(1, value))

    implicitHeight: 18

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness
        radius: height / 2
        color: Theme.bg3

        Rectangle {
            width: parent.width * root.shown
            height: parent.height
            radius: height / 2
            color: root.color
        }
    }
    Rectangle {
        visible: root.interactive && (area.containsMouse || area.pressed)
        x: track.width * root.shown - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 14; height: 14; radius: 7
        color: root.color
    }

    MouseArea {
        id: area
        property real dragValue: 0
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        function at(x) { return Math.max(0, Math.min(1, x / width)); }
        onPressed: m => dragValue = at(m.x)
        onPositionChanged: m => { if (pressed) dragValue = at(m.x); }
        onReleased: root.moved(dragValue)
    }
}

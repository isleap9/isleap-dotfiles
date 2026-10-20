import QtQuick
import qs

// Material 3 slider: thick rounded track, a gap, and a slim handle bar.
// Bind `value` (0–1); handle `moved(value)` (fires while dragging) and `released()`.
Item {
    id: root

    property real value: 0
    property bool interactive: true
    property color color: Theme.accent
    property color trackColor: Theme.bg3
    property int trackHeight: 14
    property string icon: ""               // optional icon drawn inside the track, at the start
    property color iconColor: Theme.bg0
    signal moved(real value)
    signal released

    readonly property real shown: area.pressed ? area.dragValue : Math.max(0, Math.min(1, value))
    readonly property real handleX: shown * (width - 4)

    implicitWidth: 200
    implicitHeight: 32

    // Active part (left of the handle)
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(root.trackHeight, root.handleX - 5)
        height: root.trackHeight
        radius: height / 2
        color: root.color
        topRightRadius: 3; bottomRightRadius: 3
        Behavior on width { enabled: !area.pressed; NumberAnimation { duration: 120 } }
    }
    // Inactive part (right of the handle)
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Math.min(root.width - root.trackHeight, root.handleX + 9)
        width: root.width - x
        height: root.trackHeight
        radius: height / 2
        color: root.trackColor
        topLeftRadius: 3; bottomLeftRadius: 3
        Behavior on x { enabled: !area.pressed; NumberAnimation { duration: 120 } }
    }
    // Handle
    Rectangle {
        x: root.handleX
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: area.pressed ? root.height : root.height - 4
        radius: 2
        color: root.color
        Behavior on x { enabled: !area.pressed; NumberAnimation { duration: 120 } }
        Behavior on height { NumberAnimation { duration: 100 } }
    }
    Text {
        visible: root.icon !== ""
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.shown > 0.08 ? root.iconColor : Theme.fg2
        font.family: Theme.iconFont
        font.variableAxes: Theme.iconAxes
        font.pixelSize: root.trackHeight - 2
    }

    MouseArea {
        id: area
        property real dragValue: 0
        anchors.fill: parent
        anchors.margins: -4
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        function at(x) { return Math.max(0, Math.min(1, (x - 4) / (width - 8))); }
        onPressed: m => { dragValue = at(m.x); root.moved(dragValue); }
        onPositionChanged: m => { if (pressed) { dragValue = at(m.x); root.moved(dragValue); } }
        onReleased: root.released()
    }
    WheelHandler {
        enabled: root.interactive
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.02 : -0.02))))
    }
}

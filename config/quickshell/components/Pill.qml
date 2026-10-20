import QtQuick
import QtQuick.Layouts
import qs

// Rounded "pill" background used by every bar module (like #clock, #tray… in Waybar)
Rectangle {
    id: pill

    default property alias content: row.data
    property alias spacing: row.spacing
    // flat = no background of its own (inside a shared pill, or the Sleek bar)
    property bool flat: false
    // Turned off in Settings → Bar → Modules (modules bind this to Config.bar.modules.*)
    property bool shown: true
    visible: shown
    property int padding: flat ? BarConfig.flatPadding : 18
    property bool interactive: true
    readonly property alias hovered: mouse.containsMouse

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitHeight: Theme.barHeight
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    color: flat ? "transparent" : Theme.bg1

    Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.animMs } }

    // Declared before the row so child items with their own MouseArea (tray) win
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: pill.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => pill.clicked(m)
        onWheel: w => pill.scrolled(w)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}

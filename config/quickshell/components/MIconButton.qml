import QtQuick
import qs

// Material 3 icon button. Styles: standard (transparent), tonal (bg2), filled (accent).
// `selected` = toggled on (tonal accent).
Rectangle {
    id: root

    property string icon
    property string style: "standard"
    property bool selected: false
    property int size: 40
    signal clicked

    readonly property color fg: style === "filled" ? Theme.bg0 : selected ? Theme.accent : Theme.fg1

    implicitWidth: size
    implicitHeight: size
    radius: area.pressed ? size / 3 : size / 2
    Behavior on radius { NumberAnimation { duration: 120 } }
    opacity: enabled ? 1 : 0.38
    color: style === "filled" ? Theme.accent
        : selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
        : style === "tonal" ? Theme.bg2 : "transparent"

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.fg
        opacity: area.pressed ? 0.12 : area.containsMouse ? 0.08 : 0
    }
    CenteredIcon {
        text: root.icon
        color: root.fg
        size: Math.round(root.size * 0.5)
        fill: area.containsMouse || root.selected || root.style === "filled" ? 1 : 0
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }
}

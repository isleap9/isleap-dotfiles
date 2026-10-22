import QtQuick
import QtQuick.Effects
import qs

// The Arch Linux logo (official SVG), drawn in any color. Material Symbols has no distro
// logos, so this replaces the old Nerd Font glyph.
Item {
    id: root

    property color color: Theme.fg1
    property int size: 18

    implicitWidth: size
    implicitHeight: size

    Image {
        id: logo
        anchors.fill: parent
        source: "file:///usr/share/pixmaps/archlinux-logo.svg"
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        smooth: true
        visible: false
        layer.enabled: true
    }
    // A plain rectangle of the color, cut to the logo's shape
    Rectangle {
        anchors.fill: parent
        color: root.color
        Behavior on color { ColorAnimation { duration: Theme.animMs } }
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: logo
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }
}

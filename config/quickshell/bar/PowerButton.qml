import QtQuick
import qs
import qs.components

// Power menu button (Material: icon in a tonal circle)
Pill {
    id: root
    stateLayer: false
    bubble: false
    onClicked: Globals.powerMenuOpen = !Globals.powerMenuOpen
    Rectangle {
        implicitWidth: Math.min(30, Theme.barHeight - 10)
        implicitHeight: implicitWidth
        radius: width / 2
        color: Qt.rgba(BarConfig.accentColor.r, BarConfig.accentColor.g, BarConfig.accentColor.b,
            root.pressed ? 0.34 : root.hovered ? 0.26 : 0.18)
        Behavior on color { ColorAnimation { duration: 120 } }
        CenteredIcon {
            text: "power_settings_new"
            color: BarConfig.accentColor
            size: BarConfig.iconSize - 2
        }
    }
}

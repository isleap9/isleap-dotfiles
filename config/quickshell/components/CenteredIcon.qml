import QtQuick
import qs

// A Material Symbols icon centered in its parent (the font draws every icon centered on a square
// grid, so plain center alignment is exact). text: the icon name, e.g. "power_settings_new".
Text {
    property int size: 18
    property real fill: 0                  // 0 outlined → 1 filled (animated)
    Behavior on fill { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    anchors.fill: parent
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.family: Theme.iconFont
    font.variableAxes: Theme.iconAxesWith(fill)
    font.pixelSize: size
    Behavior on color { ColorAnimation { duration: 120 } }
}

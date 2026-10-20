import QtQuick
import qs

// Bold text matching the Waybar modules (font-weight: 900)
Text {
    property bool icon: false

    color: Theme.fg1
    font.family: icon ? Theme.iconFont : Theme.font
    font.pixelSize: icon ? Theme.fontSize + 3 : Theme.fontSize
    font.weight: icon ? Font.Normal : Font.Black
    verticalAlignment: Text.AlignVCenter

    Behavior on color { ColorAnimation { duration: Theme.animMs } }
}

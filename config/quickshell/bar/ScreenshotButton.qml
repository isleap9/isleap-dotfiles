import QtQuick
import qs
import qs.components

// Click: screenshot a region. Right-click: the capture menu (screen, window, color picker).
Pill {
    onClicked: m => m.button === Qt.RightButton
        ? Globals.openControlCenter("capture")
        : Globals.run("hyprshot -m region --output-folder ~/Pictures/Screenshots")
    BarText { icon: true; text: "󰹑" }
}

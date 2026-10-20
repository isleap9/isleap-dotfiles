import QtQuick
import qs
import qs.components

// Opens the control center
Pill {
    onClicked: Globals.openControlCenter("main")
    BarText { icon: true; text: "settings" }
}

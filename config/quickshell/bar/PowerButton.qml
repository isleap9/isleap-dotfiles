import QtQuick
import qs
import qs.components

// Power menu button
Pill {
    onClicked: Globals.powerMenuOpen = !Globals.powerMenuOpen
    BarText { icon: true; text: "󰐥" }
}

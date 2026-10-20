import QtQuick
import qs
import qs.components

// Power menu button
Pill {
    shown: Config.bar.modules.power
    onClicked: Globals.powerMenuOpen = !Globals.powerMenuOpen
    BarText { icon: true; text: "󰐥" }
}

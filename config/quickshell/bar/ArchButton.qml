import QtQuick
import qs
import qs.components

// Arch logo: click = app launcher, right click = control center
Pill {
    onClicked: m => m.button === Qt.RightButton
        ? Globals.openControlCenter("main")
        : Globals.launcherOpen = !Globals.launcherOpen
    BarText { icon: true; text: "󰣇"; font.pixelSize: BarConfig.iconSize + 2 }
}

import QtQuick
import qs
import qs.components

// Arch logo: click = app launcher, right click = control center
Pill {
    id: root
    onClicked: m => m.button === Qt.RightButton
        ? Globals.openControlCenter("main")
        : Globals.launcherOpen = !Globals.launcherOpen
    ArchLogo {
        size: BarConfig.iconSize + 1
        color: root.iconColor
        // Small lift on hover, like the other bar icons filling in
        scale: root.hovered ? 1.12 : 1
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
    }
}

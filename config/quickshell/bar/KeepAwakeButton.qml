import QtQuick
import qs
import qs.components

// Keep awake: click to stop the screen from sleeping/locking (accent when on)
Pill {
    active: Globals.keepAwake
    onClicked: Globals.setKeepAwake(!Globals.keepAwake)
    BarText {
        icon: true
        text: Globals.keepAwake ? "coffee" : "coffee"
        color: Globals.keepAwake ? BarConfig.accentColor : parent.parent.iconColor
    }
}

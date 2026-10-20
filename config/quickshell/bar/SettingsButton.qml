import QtQuick
import qs
import qs.components

// Opens the Settings app
Pill {
    onClicked: Globals.openSettings("")
    BarText { icon: true; text: "settings" }
}

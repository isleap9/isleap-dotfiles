import QtQuick
import qs
import qs.components

// Opens quick settings
Pill {
    id: root
    property var screen: null
    onClicked: Globals.toggleQuickSettings("main", screen)
    BarText { icon: true; text: "settings" }
}

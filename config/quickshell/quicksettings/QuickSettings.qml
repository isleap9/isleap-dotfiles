import QtQuick
import qs
import qs.components

// Quick settings (Material 3): drops out of the right end of the bar.
// Open: click the network or volume widget, or SUPER+X.  qs ipc call quicksettings open wifi
Popout {
    id: root

    open: Globals.quickSettingsOpen
    screen: Globals.quickSettingsScreen
    align: "right"
    namespace: "quickshell-quicksettings"
    onClosed: Globals.quickSettingsOpen = false

    content: Component {
        // Fixed width; pages fill it
        Item {
            implicitWidth: 420
            implicitHeight: page.item?.implicitHeight ?? 0
            Loader {
                id: page
                anchors.fill: parent
                sourceComponent: ({ main: main, wifi: wifi, bluetooth: bluetooth, audio: audio })[Globals.quickSettingsPage] ?? main
            }
            Component { id: main; MainPage {} }
            Component { id: wifi; WifiPage {} }
            Component { id: bluetooth; BluetoothPage {} }
            Component { id: audio; AudioPage {} }
        }
    }
}

import QtQuick
import Quickshell
import qs

// One bar per monitor, in the layout chosen in the control center (Bar Layout page).
Scope {
    id: root

    required property ShellScreen modelData

    LazyLoader {
        active: BarConfig.layout !== "sleek"
        FloatingBar {
            screen: root.modelData
            layout: BarConfig.layout
        }
    }

    LazyLoader {
        active: BarConfig.layout === "sleek"
        SleekBar {
            screen: root.modelData
        }
    }
}

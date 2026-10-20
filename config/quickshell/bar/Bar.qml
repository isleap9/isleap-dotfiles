import QtQuick
import Quickshell
import qs

// The bar for one monitor (shell.qml makes one per screen).
// Skipped on monitors turned off in Settings → Monitors; rebuilt when the style or position changes.
Scope {
    id: root

    required property ShellScreen modelData

    readonly property bool wanted: !(Config.monitors.barHidden ?? []).includes(modelData.name)
    readonly property string shape: `${BarConfig.solid}/${BarConfig.bottom}/${BarConfig.solidFull}/${BarConfig.outerCorners}`
    property bool rebuilding: false

    // A layer-shell surface can't move between screen edges, so make a new one
    onShapeChanged: {
        rebuilding = true;
        rebuildTimer.restart();
    }
    Timer {
        id: rebuildTimer
        interval: 50
        onTriggered: root.rebuilding = false
    }

    LazyLoader {
        active: root.wanted && !root.rebuilding
        BarWindow {
            screen: root.modelData
        }
    }
}

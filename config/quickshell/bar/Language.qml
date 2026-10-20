import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.components

// Keyboard layout (UK / IT)
Pill {
    bubble: false
    id: root

    property string layout: ""

    function shortName(name) {
        if (name.includes("English")) return "UK";
        if (name.includes("Italian")) return "IT";
        return name.slice(0, 2).toUpperCase();
    }

    // Initial value
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards;
                    const main = kbs.find(k => k.main) ?? kbs[0];
                    root.layout = root.shortName(main.active_keymap);
                } catch (e) {}
            }
        }
    }

    // Live updates when the layout changes
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const parts = event.data.split(",");
            root.layout = root.shortName(parts[parts.length - 1]);
        }
    }

    stateLayer: BarConfig.opt(root.settings, "label") === false
    // Material tonal chip with the layout code (UK / IT)
    BarText { visible: BarConfig.opt(root.settings, "icon") === true; icon: true; text: "keyboard" }
    Rectangle {
        visible: BarConfig.opt(root.settings, "label") !== false
        implicitWidth: code.implicitWidth + 16
        implicitHeight: Math.min(26, Theme.barHeight - 12)
        radius: 8
        // Inside a shared bubble the bubble is the background; on its own it's a tonal chip
        color: root.inGroup ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, root.pressed ? 0.16 : root.hovered ? 0.08 : 0)
            : Qt.rgba(BarConfig.accentColor.r, BarConfig.accentColor.g, BarConfig.accentColor.b, root.pressed ? 0.34 : root.hovered ? 0.26 : 0.18)
        Behavior on color { ColorAnimation { duration: 120 } }
        BarText {
            id: code
            anchors.centerIn: parent
            text: root.layout
            color: root.inGroup ? root.textColor : BarConfig.accentColor
            font.pixelSize: root.inGroup ? BarConfig.textSize - 1 : BarConfig.textSize - 3
            font.weight: Font.Bold
        }
    }
}

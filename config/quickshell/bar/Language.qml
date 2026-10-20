import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.components

// Keyboard layout (UK / IT)
Pill {
    id: root
    shown: Config.bar.modules.language

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

    BarText { icon: true; text: "󰌌" }
    BarText { text: root.layout }
}

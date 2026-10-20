import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.components

// Reuses your existing Waybar weather script (wttr.in, Bari)
Pill {
    id: root

    property string text: "…"
    property string tooltip: ""
    readonly property string script: Quickshell.env("HOME") + "/.config/waybar/scripts/weather.py"

    shown: Config.bar.modules.weather && text !== ""
    onClicked: Quickshell.execDetached(["xdg-open", "https://wttr.in/" + encodeURIComponent(Config.bar.weatherCity)])

    Process {
        id: proc
        command: ["python3", root.script, Config.bar.weatherCity]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.text = data.text ?? "";
                    root.tooltip = data.tooltip ?? "";
                } catch (e) {
                    root.text = "";
                }
            }
        }
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: proc.running = true
    }

    BarText { text: root.text }

    Tooltip {
        target: root
        show: root.hovered && root.tooltip !== ""
        text: root.tooltip
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.components

// Audio visualizer bars from cava (raw output mode)
Pill {
    bubble: false
    id: root

    property var levels: Array(14).fill(0)

    interactive: false
    spacing: 3

    Process {
        running: root.visible
        command: ["cava", "-p", Quickshell.shellDir + "/cava.conf"]
        stdout: SplitParser {
            onRead: line => {
                const vals = line.split(";").filter(v => v !== "").map(Number);
                if (vals.length > 0) root.levels = vals;
            }
        }
    }

    Repeater {
        model: root.levels.length

        Rectangle {
            required property int index
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 4
            implicitHeight: 3 + (root.levels[index] ?? 0) * 2
            radius: 2
            color: root.textColor

            Behavior on implicitHeight { NumberAnimation { duration: 60 } }
        }
    }
}

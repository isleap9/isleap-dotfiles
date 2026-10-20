import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.components

// Your own widget: runs a command every few seconds and shows its output (first line).
// Options: icon, command, interval, click command.
Pill {
    id: root

    readonly property string cmd: BarConfig.opt(settings, "command") ?? ""
    readonly property string clickCmd: BarConfig.opt(settings, "click") ?? ""
    readonly property string iconText: BarConfig.opt(settings, "icon") ?? ""
    property string output: ""

    shown: iconText !== "" || output !== ""
    onClicked: if (clickCmd) Globals.run(clickCmd)

    Process {
        id: proc
        command: ["sh", "-c", root.cmd]
        stdout: StdioCollector { onStreamFinished: root.output = text.split("\n")[0].trim() }
    }
    Timer {
        interval: Math.max(1, BarConfig.opt(root.settings, "interval") ?? 10) * 1000
        running: root.cmd !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }

    BarText { visible: root.iconText !== ""; icon: true; text: root.iconText }
    BarText { visible: root.output !== ""; text: root.output }
}

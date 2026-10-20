import QtQuick
import QtQuick.Layouts
import qs
import qs.components

// CPU / memory / temperature / GPU on the bar: icon + value, optional mini graph.
// kind: cpu, memory, temp, gpu.  Click: the dashboard.
Pill {
    id: root

    required property string kind
    property var screen: null
    readonly property bool graph: BarConfig.opt(settings, "graph") === true
    readonly property var s: SysStats

    readonly property var info: ({
        cpu: { icon: "memory", value: Math.round(s.cpu) + "%", usage: s.cpu, history: s.cpuHistory },
        memory: { icon: "memory_alt", value: BarConfig.opt(settings, "unit") === "gb" ? (s.memUsed / 1073741824).toFixed(1) + "G" : Math.round(s.memPercent) + "%",
                  usage: s.memPercent, history: s.memHistory },
        temp: { icon: "thermostat", value: s.cpuTemp >= 0 ? Math.round(s.cpuTemp) + "°" : "--", usage: s.cpuTemp, history: [] },
        gpu: { icon: "developer_board", value: s.gpuAvailable ? Math.round(s.gpu) + "%" : "--", usage: s.gpu, history: s.gpuHistory }
    })[kind]
    // Warn colors when it's running hot / full
    readonly property bool hot: kind === "temp" ? s.cpuTemp >= 80 : info.usage >= 90

    Component.onCompleted: SysStats.use()
    Component.onDestruction: SysStats.release()
    onClicked: Globals.toggleDashboard("overview", screen)

    BarText { icon: true; text: root.info.icon; color: root.hot ? Theme.red : root.iconColor }
    Sparkline {
        visible: root.graph && root.info.history.length > 1
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 40
        implicitHeight: Theme.barHeight - 18
        values: root.info.history
        color: root.hot ? Theme.red : root.textColor
    }
    BarText {
        id: value
        text: root.info.value
        font.features: ({ tnum: 1 })
        // Fixed width, so the bar doesn't wiggle as the number changes
        Layout.minimumWidth: metrics.width
    }
    TextMetrics { id: metrics; font: value.font; text: root.kind === "memory" ? "00.0G" : "100%" }
}

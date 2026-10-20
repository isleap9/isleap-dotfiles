import QtQuick
import QtQuick.Layouts
import qs

// One system number: gauge + value; on wider cards a graph of the last 30 seconds.
// kind: cpu, memory, gpu, disk, network
DashCard {
    id: card

    required property string kind
    readonly property bool wide: width >= 240
    readonly property bool tall: height >= 200

    readonly property var info: {
        const s = SysStats;
        switch (kind) {
        case "cpu": return {
            label: "CPU", icon: "\u{F0EE0}", usage: s.cpu / 100, value: Math.round(s.cpu) + "%",
            detail: s.cpuTemp >= 0 ? Math.round(s.cpuTemp) + "°C" : "", sub: s.cpuName, history: s.cpuHistory, max: 100 };
        case "memory": return {
            label: "Memory", icon: "\u{F035B}", usage: s.memPercent / 100, value: Math.round(s.memPercent) + "%",
            detail: s.bytes(s.memUsed), sub: `${s.bytes(s.memUsed)} of ${s.bytes(s.memTotal, 0)}`, history: s.memHistory, max: 100 };
        case "gpu": return {
            label: "GPU", icon: "\u{F08AE}", usage: s.gpu / 100, value: s.gpuAvailable ? Math.round(s.gpu) + "%" : "--",
            detail: s.gpuTemp >= 0 ? Math.round(s.gpuTemp) + "°C" : "",
            sub: s.gpuAvailable ? `${s.gpuName} · ${(s.vramUsed / 1024).toFixed(1)} / ${(s.vramTotal / 1024).toFixed(0)} GB` : "No NVIDIA GPU found",
            history: s.gpuHistory, max: 100 };
        case "disk": return {
            label: "Disk", icon: "\u{F02CA}", usage: s.diskPercent / 100, value: Math.round(s.diskPercent) + "%",
            detail: s.bytes(s.diskTotal - s.diskUsed, 0) + " free", sub: `${s.bytes(s.diskUsed, 0)} of ${s.bytes(s.diskTotal, 0)} used`, history: [], max: 100 };
        default: return {
            label: "Network", icon: "\u{F06F3}", usage: -1, value: s.rate(s.netDown),
            detail: "", sub: `\u{F0045} ${s.rate(s.netDown)}   \u{F005D} ${s.rate(s.netUp)}`, history: s.netHistory, max: 0 };
        }
    }
    // Green → yellow → red as it fills up
    readonly property color level: info.usage >= 0.9 ? Theme.red : info.usage >= 0.75 ? Theme.orange : Theme.accent

    Sparkline {
        visible: card.wide && card.info.history.length > 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * (card.tall ? 0.5 : 0.45)
        values: card.info.history
        maximum: card.info.max
        color: card.level
        opacity: 0.9
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10

        Gauge {
            visible: card.info.usage >= 0
            implicitWidth: card.tall ? 56 : 36
            implicitHeight: implicitWidth
            value: card.info.usage
            color: card.level
            Text {
                anchors.centerIn: parent
                text: card.info.icon
                color: Theme.fg1
                font.family: Theme.iconFont
                font.pixelSize: parent.width * 0.42
            }
        }
        Text {
            visible: card.info.usage < 0
            text: card.info.icon
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: 24
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: card.info.label
                elide: Text.ElideRight
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                visible: card.info.detail !== ""
                text: card.info.detail
                elide: Text.ElideRight
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: card.wide ? parent.width * 0.6 : parent.width
        spacing: 0
        Text {
            Layout.fillWidth: true
            text: card.info.value
            elide: Text.ElideRight
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 12
            color: Theme.fg1
            font.family: Theme.font
            font.pixelSize: card.tall ? 40 : card.kind === "network" && !card.wide ? 18 : 26
            font.weight: Font.Bold
            font.features: ({ tnum: 1 })
        }
        Text {
            Layout.fillWidth: true
            visible: card.wide || card.tall
            text: card.info.sub
            elide: Text.ElideRight
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

// Main monitor, which monitors show a bar, and where popups open.
// Resolution / arrangement are left to nwg-displays (a wrong mode can black out a screen).
Page {
    id: page

    property var monitors: []    // from `hyprctl monitors -j`

    readonly property string mainName: Globals.mainScreen?.name ?? ""

    function refresh() { proc.running = true; }

    Process {
        id: proc
        running: true
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.monitors = JSON.parse(text); } catch (e) { page.monitors = []; }
            }
        }
    }
    // Refresh when a monitor is plugged in or removed
    Connections {
        target: Quickshell
        function onScreensChanged() { page.refresh(); }
    }

    function label(m) {
        return [m.make, m.model].filter(x => x && x !== "Unknown").join(" ") || m.description || m.name;
    }

    Section {
        title: "Your monitors"
        description: "Click a monitor to make it your main one."

        // Scaled picture of the real arrangement
        Item {
            id: diagram
            Layout.fillWidth: true
            Layout.margins: 12
            implicitHeight: 220

            // Logical size of each monitor (pixels / scale) and the area they cover together
            readonly property var boxes: page.monitors.map(m => ({
                m, x: m.x, y: m.y, w: m.width / (m.scale || 1), h: m.height / (m.scale || 1)
            }))
            readonly property real minX: Math.min(...boxes.map(b => b.x), 0)
            readonly property real minY: Math.min(...boxes.map(b => b.y), 0)
            readonly property real spanW: Math.max(...boxes.map(b => b.x + b.w), 1) - minX
            readonly property real spanH: Math.max(...boxes.map(b => b.y + b.h), 1) - minY
            readonly property real k: Math.min((width - 8) / spanW, (height - 8) / spanH)
            readonly property real offX: (width - spanW * k) / 2
            readonly property real offY: (height - spanH * k) / 2

            Repeater {
                model: diagram.boxes

                Rectangle {
                    id: screenBox
                    required property var modelData
                    readonly property var mon: modelData.m
                    readonly property bool isMain: mon.name === page.mainName
                    readonly property bool hasBar: !(Config.monitors.barHidden ?? []).includes(mon.name)

                    x: diagram.offX + (modelData.x - diagram.minX) * diagram.k + 3
                    y: diagram.offY + (modelData.y - diagram.minY) * diagram.k + 3
                    width: modelData.w * diagram.k - 6
                    height: modelData.h * diagram.k - 6
                    radius: 12
                    color: isMain ? Theme.bg3 : Theme.bg2
                    border.width: isMain ? 3 : boxArea.containsMouse ? 2 : 1
                    border.color: isMain ? Theme.accent : boxArea.containsMouse ? Theme.fg2 : Theme.bg4

                    // Bar strip, if this monitor shows a bar
                    Rectangle {
                        visible: screenBox.hasBar
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        y: BarConfig.bottom ? parent.height - 16 : 8
                        height: 6
                        radius: 3
                        color: screenBox.isMain ? Theme.accent : Theme.fg2
                        opacity: 0.6
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (screenBox.isMain ? "star  " : "") + screenBox.mon.name
                            color: Theme.fg1
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: Theme.fontSize + 2
                            font.weight: Font.Bold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: `${screenBox.mon.width}×${screenBox.mon.height} · ${Math.round(screenBox.mon.refreshRate)} Hz`
                            color: Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: screenBox.isMain
                            text: "Main"
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.Black
                        }
                    }

                    MouseArea {
                        id: boxArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Config.monitors.main = screenBox.mon.name
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: page.monitors.length === 0
                text: "Reading monitors…"
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }
    }

    Section {
        title: "Main monitor"
        Option {
            icon: "star"
            label: "Main monitor"
            description: Config.monitors.main === "" ? "Not set — using the biggest screen" : ""
            Segmented {
                options: page.monitors.map(m => [m.name, m.name])
                current: page.mainName
                onSelected: v => Config.monitors.main = v
            }
        }
        Option {
            icon: "menu"
            label: "Open popups on"
            description: Config.monitors.popups === "main"
                ? "Launcher, control center, notifications and power menu always open on the main monitor"
                : "They open on the monitor you're working on"
            Segmented {
                options: [["focused", "Focused monitor"], ["main", "Main monitor"]]
                current: Config.monitors.popups
                onSelected: v => Config.monitors.popups = v
            }
        }
    }

    Section {
        title: "Bar"
        description: "Choose which monitors show the bar"

        Repeater {
            model: page.monitors

            Option {
                id: barRow
                required property var modelData
                icon: "toolbar"
                label: `${modelData.name} — ${page.label(modelData)}`
                description: modelData.name === page.mainName ? "Main monitor" : ""
                Toggle {
                    checked: !(Config.monitors.barHidden ?? []).includes(barRow.modelData.name)
                    onToggled: {
                        const hidden = (Config.monitors.barHidden ?? []).filter(n => n !== barRow.modelData.name);
                        if (checked) hidden.push(barRow.modelData.name);
                        Config.monitors.barHidden = hidden;
                    }
                }
            }
        }
    }

    Section {
        title: "Details"
        description: "Resolution, refresh rate, scale and arrangement are set in Hyprland (~/.config/hypr/modules/monitors.lua)."

        Repeater {
            model: page.monitors

            Option {
                required property var modelData
                icon: "monitor"
                label: `${modelData.name} — ${page.label(modelData)}`
                description: `${modelData.width}×${modelData.height} at ${modelData.refreshRate.toFixed(0)} Hz · scale ${modelData.scale} · position ${modelData.x}, ${modelData.y}`
            }
        }
        Option {
            icon: "settings"
            label: "Change resolution or arrangement"
            description: "Opens monitors.lua in micro. Hyprland applies it when you save."
            PillButton {
                text: "Edit"
                onClicked: Quickshell.execDetached(["kitty", "-e", "micro", Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"])
            }
        }
    }
}

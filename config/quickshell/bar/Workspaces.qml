import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

// Workspace indicator. Always shows at least workspaces 1-4 (your persistent workspaces).
// style:
//   "default" — wide accent pill for the active one, bg3 = occupied, bg2 = empty
//   "classic" — Waybar default2/minimal: bg3 track, fg2 buttons with icons, accent active
//   "sleek"   — Waybar sleek: tiny bg4 dots, accent active
Pill {
    id: root
    stateLayer: false     // its parts have their own hover highlights
    bubble: false

    required property ShellScreen screen
    property string style: BarConfig.opt(settings, "style") ?? "default"

    readonly property color activeColor: BarConfig.isCustom
        ? BarConfig.color(BarConfig.opt(settings, "activeColor"), BarConfig.accentColor) : BarConfig.accentColor

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
    readonly property var existing: Hyprland.workspaces.values
        .filter(w => w.id > 0)
        .map(w => w.id)
    readonly property int count: Math.max(Config.bar.minWorkspaces, ...existing)

    // Per-style dot sizes: [height, width, activeWidth, hoverWidth, gap]
    readonly property var size: ({
        default: [22, 22, 46, 38, 4],
        classic: [24, 26, 40, 26, 2],
        sleek:   [12, 14, 32, 14, 2]
    })[style] ?? [22, 22, 46, 38, 4]

    padding: style === "default" ? 4 : flat ? 0 : 8
    spacing: 0
    onScrolled: w => Globals.dispatch(`hl.dsp.focus({ workspace = "${w.angleDelta.y > 0 ? "e-1" : "e+1"}" })`)

    Rectangle {
        // Track behind the buttons (only visible in the classic style)
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: root.size[0] + 6
        implicitWidth: root.style === "classic" ? Math.max(100, dots.implicitWidth + 6) : dots.implicitWidth
        radius: height / 2
        color: root.style === "classic" ? Theme.bg3 : "transparent"

        RowLayout {
            id: dots
            anchors.centerIn: parent
            spacing: 0

            Repeater {
                model: root.count

                Rectangle {
                    id: dot
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool active: wsId === root.activeId
                    readonly property bool occupied: root.existing.includes(wsId)

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: root.size[4]
                    Layout.rightMargin: root.size[4]
                    implicitHeight: root.size[0]
                    implicitWidth: active ? root.size[2] : hover.containsMouse ? root.size[3] : root.size[1]
                    radius: height / 2
                    color: {
                        if (active) return root.activeColor;
                        if (root.style === "classic") return Theme.fg2;
                        if (root.style === "sleek") return Theme.bg4;
                        return hover.containsMouse ? Theme.fg2 : occupied ? Theme.bg3 : Theme.bg2;
                    }

                    Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.animMs } }

                    // Classic style shows icons like the old Waybar config
                    Text {
                        anchors.centerIn: parent
                        visible: root.style === "classic"
                        text: dot.active ? "\u{F0BAF}" : ""
                        color: dot.active ? Theme.bg1 : Theme.fg1
                        font.family: Theme.brandFont
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Globals.goToWorkspace(dot.wsId)
                    }
                }
            }
        }
    }
}

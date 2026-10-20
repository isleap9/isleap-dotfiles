import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs

// A panel that drops out of the bar (Material 3). With a one-piece bar (Floating or Attached)
// it's part of the bar: same color, no gap, curved corners where they meet, and it slides out
// from under it. With pills it floats just below. Esc or a click outside closes it.
//   open: bind to a Globals flag;  closed(): set that flag to false
//   align: left, center or right (lines up with that end of the bar), or "at": centered under
//          `atX` (screen x, e.g. a tray icon), kept inside the bar
//   content: a Component with the panel's contents
LazyLoader {
    id: root

    property bool open: false
    property string align: "right"
    property real atX: 0
    property var screen: null
    property string namespace: "quickshell-popout"
    property Component content
    signal closed
    signal keyPressed(var event)

    active: open

    PanelWindow {
        id: win

        readonly property bool attached: BarConfig.solid
        readonly property bool atBottom: BarConfig.bottom
        readonly property int r: Config.panels.joint
        readonly property int gap: attached ? 0 : 10
        readonly property color fill: BarConfig.solid ? BarConfig.solidColor : BarConfig.surface(Theme.bg0)
        // How far in from the screen edge the bar ends. Attached at the left/right end, the panel
        // is flush with the bar's end (one straight edge), with a curved joint only on the inner side.
        readonly property real barWidth: Globals.barWidths[screen?.name] ?? (screen?.width ?? 0)
        readonly property real inset: attached ? Math.max(0, ((screen?.width ?? 0) - barWidth) / 2) : Theme.barSideMargin
        readonly property bool flushLeft: attached && root.align === "left"
        readonly property bool flushRight: attached && root.align === "right"
        readonly property int leftCorner: attached && !flushLeft ? r : 0
        readonly property int rightCorner: attached && !flushRight ? r : 0
        Component.onCompleted: if (flushLeft || flushRight) Globals.barJoin = `${screen.name}:${root.align}`
        Component.onDestruction: if (Globals.barJoin === `${screen?.name}:${root.align}`) Globals.barJoin = ""

        screen: root.screen ?? Globals.popupScreen
        anchors.top: !atBottom
        anchors.bottom: atBottom
        anchors.left: root.align === "left" || root.align === "at"
        anchors.right: root.align === "right"
        exclusiveZone: 0
        margins.top: atBottom ? 0 : gap
        margins.bottom: atBottom ? gap : 0
        // "at": centered under atX, but never past the bar's ends
        readonly property real atLeft: Math.max(inset, Math.min((screen?.width ?? 0) - inset - implicitWidth,
            root.atX - implicitWidth / 2))
        margins.left: root.align === "left" ? inset : root.align === "at" ? atLeft : 0
        margins.right: root.align === "right" ? inset : 0
        implicitWidth: panel.width + leftCorner + rightCorner
        implicitHeight: panel.height
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: root.namespace

        HyprlandFocusGrab {
            active: true
            windows: [win]
            onCleared: root.closed()
        }

        MCorner {
            visible: win.leftCorner > 0
            width: win.r; height: win.r
            y: win.atBottom ? parent.height - win.r : 0
            flipX: true; flipY: win.atBottom
            color: win.fill
        }
        MCorner {
            visible: win.rightCorner > 0
            width: win.r; height: win.r
            x: parent.width - win.r
            y: win.atBottom ? parent.height - win.r : 0
            flipY: win.atBottom
            color: win.fill
        }

        Item {
            id: panel
            x: win.leftCorner
            width: body.implicitWidth + 32
            height: body.implicitHeight + 32
            clip: win.attached
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) { root.closed(); e.accepted = true; return; }
                root.keyPressed(e);
            }
            Behavior on height { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }

            Item {
                id: sheet
                width: parent.width
                height: parent.height
                opacity: win.attached ? 1 : 0
                transform: Translate { id: slide }
                Component.onCompleted: {
                    slide.y = win.attached ? (win.atBottom ? 1 : -1) * Math.max(panel.height, 300) : (win.atBottom ? 16 : -16);
                    anim.start();
                }
                ParallelAnimation {
                    id: anim
                    NumberAnimation { target: sheet; property: "opacity"; to: 1; duration: Theme.animMs * 0.8; easing.type: Easing.OutCubic }
                    NumberAnimation { target: slide; property: "y"; to: 0; duration: Theme.animMs * 1.3; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    readonly property int overhang: win.attached ? radius : 0
                    width: parent.width
                    y: win.atBottom ? 0 : -overhang
                    height: parent.height + overhang
                    radius: Config.panels.radius
                    // Flush with the bar's end: that top corner is square (bottom stays rounded)
                    topRightRadius: win.flushRight && !win.atBottom ? 0 : radius
                    topLeftRadius: win.flushLeft && !win.atBottom ? 0 : radius
                    bottomRightRadius: win.flushRight && win.atBottom ? 0 : radius
                    bottomLeftRadius: win.flushLeft && win.atBottom ? 0 : radius
                    color: win.fill
                    border.width: win.attached ? BarConfig.borderWidth : 1
                    border.color: win.attached ? BarConfig.borderColor : Theme.bg3
                }

                Loader {
                    id: body
                    anchors.centerIn: parent
                    sourceComponent: root.content
                }
            }
        }
    }
}

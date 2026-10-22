import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Material title bar for the shell's app windows (Settings, Files).
// No title text, just a drag area. Drag it to move the window, double-click to maximize / restore. Buttons: maximize, close.
// The left part can continue a sidebar's color (sidebarWidth / sidebarColor).
Item {
    id: bar

    property int sidebarWidth: 0
    property color sidebarColor: Theme.bg1
    property color color: Theme.bg0
    signal closeRequested

    // Our Hyprland window, for the maximized state. Matched by title, and by size when several
    // windows share the title (e.g. two Files windows)
    property string windowTitle: ""
    readonly property var toplevel: {
        const mine = Hyprland.toplevels.values.filter(t => t.title === bar.windowTitle
            && (t.lastIpcObject?.class ?? "org.quickshell") === "org.quickshell");
        if (mine.length <= 1) return mine[0] ?? null;
        const w = bar.Window.window;
        return mine.find(t => {
            const size = t.lastIpcObject?.size ?? [];
            return w && Math.abs(size[0] - w.width) <= 2 && Math.abs(size[1] - w.height) <= 2;
        }) ?? null;
    }
    readonly property bool maximized: (toplevel?.lastIpcObject?.fullscreen ?? 0) > 0

    function toggleMaximize() {
        // Hyprland "maximize" (fullscreen mode 1) on this window, which is the focused one
        Globals.dispatch(`hl.dsp.window.fullscreen({ mode = 1 })`);
        refresh.restart();
    }
    // Hyprland doesn't push the new state by itself; ask again shortly after changes
    Timer { id: refresh; interval: 120; onTriggered: Hyprland.refreshToplevels() }
    Component.onCompleted: refresh.restart()
    onWidthChanged: refresh.restart()

    implicitHeight: 40

    Rectangle {
        width: bar.sidebarWidth
        height: parent.height
        color: bar.sidebarColor
    }
    Rectangle {
        x: bar.sidebarWidth
        width: parent.width - bar.sidebarWidth
        height: parent.height
        color: bar.color
    }

    // Drag to move (the compositor does the moving), double-click to maximize
    DragHandler {
        target: null
        grabPermissions: PointerHandler.CanTakeOverFromAnything
        onActiveChanged: if (active) bar.Window.window.startSystemMove()
    }
    TapHandler {
        onDoubleTapped: bar.toggleMaximize()
    }


    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        WindowButton {
            icon: bar.maximized ? "close_fullscreen" : "open_in_full"
            onClicked: bar.toggleMaximize()
        }
        WindowButton {
            icon: "close"
            danger: true
            onClicked: bar.closeRequested()
        }
    }

    // M3 icon button; the close one turns into a red container on hover
    component WindowButton: Rectangle {
        id: btn
        property string icon
        property bool danger: false
        signal clicked
        readonly property bool hot: area.containsMouse

        width: 30
        height: 30
        radius: area.pressed ? 9 : 15
        Behavior on radius { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        color: danger && hot ? Theme.red : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: btn.danger && btn.hot ? Theme.bg0 : Theme.fg1
            opacity: area.pressed ? 0.12 : btn.hot && !btn.danger ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
        Text {
            id: glyph
            anchors.centerIn: parent
            text: btn.icon
            color: btn.danger && btn.hot ? Theme.bg0 : btn.hot ? Theme.fg1 : Theme.fg2
            Behavior on color { ColorAnimation { duration: 150 } }
            font.family: Theme.iconFont
            property real fill: btn.hot ? 1 : 0
            Behavior on fill { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            font.variableAxes: Theme.iconAxesWith(fill)
            font.pixelSize: 18
            // Icon swaps (maximize ⇄ restore) spin and pop in
            onTextChanged: swap.restart()
            ParallelAnimation {
                id: swap
                NumberAnimation { target: glyph; property: "rotation"; from: -90; to: 0; duration: Theme.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel }
                NumberAnimation { target: glyph; property: "scale"; from: 0.6; to: 1; duration: Theme.animMs; easing.type: Easing.OutBack }
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}

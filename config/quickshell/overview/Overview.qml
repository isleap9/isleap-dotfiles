import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs
import qs.components

// Workspace overview (SUPER+TAB): every workspace with live previews of its windows.
//   Click a window: focus it.  Click a workspace: go there.  Drag a window onto another
//   workspace: move it there.  Middle click a window: close it.  Esc or 1–9 to jump.
LazyLoader {
    id: loader

    // Open/close animation (Settings → Animations)
    property PanelMotion motion: PanelMotion { style: Config.animations.overview; open: Globals.overviewOpen }
    active: motion.needed

    PanelWindow {
        id: win

        readonly property var wsList: {
            const used = Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id);
            const count = Math.max(Config.bar.minWorkspaces, ...used, 1);
            return Array.from({ length: count }, (_, i) => i + 1);
        }
        readonly property int columns: wsList.length <= 4 ? wsList.length : wsList.length <= 8 ? 4 : 5
        readonly property real tileW: Math.min(460, (width * 0.86 - (columns - 1) * 20) / columns)
        readonly property var thisMonitor: Hyprland.monitorFor(screen)
        property var walls: ({})           // monitor name → wallpaper path
        // Dragging a window
        property var dragging: null
        property point dragPos
        property int dropTarget: -1

        function close() { Globals.overviewOpen = false; }
        function goTo(id) { Globals.goToWorkspace(id); close(); }
        function focusWindow(t) {
            Globals.dispatch(`hl.dsp.focus({ window = "address:0x${t.address}" })`);
            close();
        }
        function moveWindow(t, id) {
            Globals.dispatch(`hl.dsp.window.move({ workspace = "${id}", window = "address:0x${t.address}", follow = false })`);
            refresh.restart();
        }
        Timer { id: refresh; interval: 150; onTriggered: { Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces(); } }
        Component.onCompleted: { Hyprland.refreshToplevels(); Hyprland.refreshMonitors(); }

        Process {
            running: true
            command: ["sh", "-c", "awww query 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = {};
                    for (const line of text.split("\n")) {
                        const r = line.match(/^:?\s*([^:]+):.*image: (.+)$/);
                        if (r) m[r[1].trim()] = r[2].trim();
                    }
                    win.walls = m;
                }
            }
        }

        screen: Globals.focusedScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Globals.overviewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-overview"

        // Scrim
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.94)
            opacity: Math.min(1, Math.max(0, loader.motion.progress))
            MouseArea { anchors.fill: parent; onClicked: win.close() }
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape || e.key === Qt.Key_Tab) win.close();
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) win.goTo(e.key - Qt.Key_0);
            }
        }

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            spacing: 24
            opacity: loader.motion.opacityValue
            scale: loader.motion.scaleValue
            transform: Translate { y: loader.motion.offset }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Workspaces"
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 10
                font.weight: Font.Bold
            }

            GridLayout {
                id: grid
                columns: win.columns
                rowSpacing: 20
                columnSpacing: 20

                Repeater {
                    id: tiles
                    model: win.wsList

                    Item {
                        id: tile
                        required property int modelData
                        required property int index
                        readonly property int wsId: modelData
                        readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                        readonly property var mon: ws?.monitor ?? win.thisMonitor
                        readonly property real scaleF: win.tileW / Math.max(1, mon?.width ?? 1920)
                        readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace?.id === tile.wsId)
                        readonly property bool shown: (mon?.activeWorkspace?.id ?? -1) === wsId
                        readonly property bool target: win.dropTarget === index

                        implicitWidth: win.tileW
                        implicitHeight: (mon?.height ?? 1080) * scaleF + 34

                        ClippingRectangle {
                            id: frame
                            width: parent.width
                            height: parent.height - 34
                            radius: 22
                            color: Theme.bg1
                            border.width: tile.target ? 4 : tile.shown ? 3 : 1
                            border.color: tile.target || tile.shown ? Theme.accent : Theme.bg3
                            Behavior on border.width { NumberAnimation { duration: 120 } }

                            Image {
                                anchors.fill: parent
                                source: win.walls[tile.mon?.name] ? "file://" + win.walls[tile.mon?.name] : ""
                                sourceSize.width: 480
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                opacity: 0.55
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.goTo(tile.wsId)
                            }

                            // Windows
                            Repeater {
                                model: tile.windows
                                ClippingRectangle {
                                    id: w
                                    required property var modelData
                                    readonly property var ipc: modelData.lastIpcObject ?? {}
                                    readonly property var at: ipc.at ?? [0, 0]
                                    readonly property var size: ipc.size ?? [0, 0]
                                    visible: size[0] > 0 && win.dragging !== modelData
                                    x: (at[0] - (tile.mon?.x ?? 0)) * tile.scaleF
                                    y: (at[1] - (tile.mon?.y ?? 0)) * tile.scaleF
                                    width: size[0] * tile.scaleF
                                    height: size[1] * tile.scaleF
                                    radius: 10
                                    color: Theme.bg2
                                    border.width: wArea.containsMouse ? 2 : 0
                                    border.color: Theme.accent

                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: w.modelData.wayland
                                        live: true
                                    }
                                    IconImage {
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 6
                                        implicitSize: Math.min(28, parent.height / 3)
                                        source: Globals.appIcon(w.ipc.class ?? "")
                                    }
                                    MouseArea {
                                        id: wArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        cursorShape: win.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                        property point start
                                        onPressed: m => start = Qt.point(m.x, m.y)
                                        onPositionChanged: m => {
                                            if (!pressed) return;
                                            if (!win.dragging && Math.hypot(m.x - start.x, m.y - start.y) > 8) {
                                                win.dragging = w.modelData;
                                                ghost.source = w;
                                            }
                                            if (win.dragging) {
                                                win.dragPos = mapToItem(null, m.x, m.y);
                                                win.dropTarget = -1;
                                                for (let i = 0; i < tiles.count; i++) {
                                                    const t = tiles.itemAt(i);
                                                    const p = t.mapFromItem(null, win.dragPos.x, win.dragPos.y);
                                                    if (p.x >= 0 && p.y >= 0 && p.x <= t.width && p.y <= t.height) win.dropTarget = i;
                                                }
                                            }
                                        }
                                        onReleased: m => {
                                            if (win.dragging) {
                                                const t = win.dropTarget >= 0 ? tiles.itemAt(win.dropTarget) : null;
                                                if (t && t.wsId !== tile.wsId) win.moveWindow(w.modelData, t.wsId);
                                                win.dragging = null;
                                                win.dropTarget = -1;
                                            }
                                        }
                                        onClicked: m => {
                                            if (m.button === Qt.MiddleButton) {
                                                Globals.dispatch(`hl.dsp.window.close({ window = "address:0x${w.modelData.address}" })`);
                                                refresh.restart();
                                            } else win.focusWindow(w.modelData);
                                        }
                                    }
                                }
                            }
                        }

                        // Workspace number + window count
                        RowLayout {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            Rectangle {
                                implicitWidth: 28; implicitHeight: 28; radius: 14
                                color: tile.shown ? Theme.accent : Theme.bg2
                                Text {
                                    anchors.centerIn: parent
                                    text: tile.wsId
                                    color: tile.shown ? Theme.bg0 : Theme.fg1
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                    font.weight: Font.Bold
                                }
                            }
                            Text {
                                text: tile.windows.length === 0 ? "Empty" : `${tile.windows.length} window${tile.windows.length === 1 ? "" : "s"}`
                                color: Theme.fg2
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Click a window to focus it · drag it to another workspace · middle-click to close · Esc"
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }

        // The window being dragged
        ShaderEffectSource {
            id: ghost
            visible: win.dragging !== null
            width: (sourceItem?.width ?? 0)
            height: (sourceItem?.height ?? 0)
            property alias source: ghost.sourceItem
            hideSource: false
            live: true
            x: win.dragPos.x - width / 2
            y: win.dragPos.y - height / 2
            opacity: 0.85
            z: 10
        }
    }
}

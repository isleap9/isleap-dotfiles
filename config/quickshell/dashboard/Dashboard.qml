import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.bar

// Dashboard (like DankMaterialShell's): Overview cards, Media and Weather tabs.
// Opens under the bar: click the clock, or SUPER+A. Esc or a click outside closes it.
// With a one-piece bar (Floating or Attached) it's part of the bar: same color, no gap,
// curved corners where they meet, and it slides out from under the bar.
// Keys: 1/2/3 or Tab switch tabs, Space play/pause.
LazyLoader {
    active: Globals.dashboardOpen

    PanelWindow {
        id: win

        readonly property var tabs: [
            { id: "overview", name: "Overview", icon: "dashboard" },
            { id: "media", name: "Media", icon: "music_note" },
            { id: "weather", name: "Weather", icon: "partly_cloudy_day" },
            { id: "wallpaper", name: "Wallpapers", icon: "wallpaper" }
        ]
        readonly property string tab: tabs.some(t => t.id === Globals.dashboardTab) ? Globals.dashboardTab : "overview"
        property bool editMode: false
        onTabChanged: editMode = false

        function cycle(d) {
            const i = tabs.findIndex(t => t.id === tab);
            Globals.dashboardTab = tabs[(i + d + tabs.length) % tabs.length].id;
        }

        screen: Globals.dashboardScreen ?? Globals.popupScreen
        anchors.top: !BarConfig.bottom
        anchors.bottom: BarConfig.bottom
        // One-piece bar (floating or attached): the dashboard grows out of its bottom edge
        readonly property bool attached: BarConfig.solid
        readonly property bool atBottom: BarConfig.bottom
        readonly property int r: Config.panels.joint   // outer corner size (attached)
        readonly property int gap: attached ? 0 : 10
        readonly property color fill: attached || BarConfig.solid ? BarConfig.solidColor : BarConfig.surface(Theme.bg0)

        // Respect the bar's reserved space, then leave the same gap as the bar
        exclusiveZone: 0
        margins.top: atBottom ? 0 : gap
        margins.bottom: atBottom ? gap : 0
        implicitWidth: panel.width + (attached ? 2 * r : 0)
        implicitHeight: panel.height
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-dashboard"

        HyprlandFocusGrab {
            active: true
            windows: [win]
            onCleared: Globals.dashboardOpen = false
        }

        // Curved corners joining the bar (attached only)
        OuterCorner {
            visible: win.attached
            width: win.r; height: win.r
            x: 0
            y: win.atBottom ? parent.height - win.r : 0
            flipX: true; flipY: win.atBottom
            color: win.fill
        }
        OuterCorner {
            visible: win.attached
            width: win.r; height: win.r
            x: parent.width - win.r
            y: win.atBottom ? parent.height - win.r : 0
            flipY: win.atBottom
            color: win.fill
        }

        Item {
            id: panel
            x: win.attached ? win.r : 0
            width: content.implicitWidth + 32
            height: content.implicitHeight + 32
            clip: win.attached
            focus: true
            Keys.forwardTo: [sheet]

            Behavior on height { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }

            // Open animation: attached = slide out from behind the bar, otherwise fade + drop
            Item {
                id: sheet
                width: parent.width
                height: parent.height
                opacity: win.attached ? 1 : 0
                // Start position is set once (not bound), so later height changes don't move it
                transform: Translate { id: slide }
                Component.onCompleted: {
                    slide.y = win.attached ? (win.atBottom ? 1 : -1) * Math.max(panel.height, 400) : (win.atBottom ? 16 : -16);
                    openAnim.start();
                }
                ParallelAnimation {
                    id: openAnim
                    NumberAnimation { target: sheet; property: "opacity"; to: 1; duration: Theme.animMs * 0.8; easing.type: Easing.OutCubic }
                    NumberAnimation { target: slide; property: "y"; to: 0; duration: Theme.animMs * 1.3; easing.type: Easing.OutCubic }
                }

                // Background. Attached: square on the bar side (it reaches past the edge, clipped)
                Rectangle {
                    readonly property int overhang: win.attached ? radius : 0
                    width: parent.width
                    y: win.atBottom ? 0 : -overhang
                    height: parent.height + overhang
                    radius: Config.panels.radius
                    color: win.fill
                    border.width: win.attached ? BarConfig.borderWidth : 1
                    border.color: win.attached ? BarConfig.borderColor : Theme.bg3
                }

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) {
                    if (win.editMode) win.editMode = false;
                    else Globals.dashboardOpen = false;
                } else if (e.key === Qt.Key_Tab) win.cycle(1);
                else if (e.key === Qt.Key_Backtab) win.cycle(-1);
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4) Globals.dashboardTab = win.tabs[e.key - Qt.Key_1].id;
                else if (e.key === Qt.Key_Space && win.tab !== "wallpaper") Players.active?.togglePlaying();
                else return;
                e.accepted = true;
            }

            ColumnLayout {
                id: content
                anchors.centerIn: parent
                spacing: 12

                // Tabs + edit button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        implicitWidth: tabRow.implicitWidth + 8
                        implicitHeight: 44
                        radius: 22
                        color: Theme.bg1

                        RowLayout {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: win.tabs
                                Rectangle {
                                    id: tabBtn
                                    required property var modelData
                                    readonly property bool current: modelData.id === win.tab
                                    implicitWidth: tabLabel.implicitWidth + 32
                                    implicitHeight: 36
                                    radius: 18
                                    color: current ? Theme.accent : tabArea.containsMouse ? Theme.bg3 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Row {
                                        id: tabLabel
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Text {
                                            text: tabBtn.modelData.icon
                                            color: tabBtn.current ? Theme.bg0 : Theme.fg1
                                            font.family: Theme.iconFont
                                            property real fill: tabBtn.current ? 1 : 0
                                            Behavior on fill { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                            font.variableAxes: Theme.iconAxesWith(fill)
                                            font.pixelSize: Theme.fontSize + 2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: tabBtn.modelData.name
                                            color: tabBtn.current ? Theme.bg0 : Theme.fg1
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 1
                                            font.weight: Font.Bold
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                    MouseArea {
                                        id: tabArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Globals.dashboardTab = tabBtn.modelData.id
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        visible: win.tab === "overview"
                        implicitWidth: editRow.implicitWidth + 28
                        implicitHeight: 40
                        radius: 20
                        color: win.editMode ? Theme.accent : editArea.containsMouse ? Theme.bg2 : Theme.bg1
                        Row {
                            id: editRow
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: win.editMode ? "check" : "edit"
                                color: win.editMode ? Theme.bg0 : Theme.fg1
                                font.family: Theme.iconFont
                                font.variableAxes: Theme.iconAxes
                                font.pixelSize: Theme.fontSize + 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: win.editMode ? "Done" : "Edit"
                                color: win.editMode ? Theme.bg0 : Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        MouseArea {
                            id: editArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.editMode = !win.editMode
                        }
                    }
                    DashButton {
                        icon: "close"
                        size: 40
                        onClicked: Globals.dashboardOpen = false
                    }
                }

                // The current tab
                Loader {
                    id: page
                    Layout.preferredWidth: item?.implicitWidth ?? 0
                    Layout.preferredHeight: item?.implicitHeight ?? 0
                    sourceComponent: ({ overview: overview, media: media, weather: weather, wallpaper: wallpaper })[win.tab]
                }
            }
            }
        }

        Component { id: overview; OverviewTab { editMode: win.editMode } }
        Component { id: media; MediaTab {} }
        Component { id: weather; WeatherTab {} }
        Component { id: wallpaper; WallpaperTab {} }
    }
}

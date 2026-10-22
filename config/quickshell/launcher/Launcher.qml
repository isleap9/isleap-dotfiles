import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import qs.components

// App launcher (SUPER+A). Type to search, ↑/↓ to pick, Enter to launch, Esc to close.
LazyLoader {
    id: loader

    // Open/close animation (Settings → Animations)
    property PanelMotion motion: PanelMotion { style: Config.animations.launcher; open: Globals.launcherOpen }
    active: motion.needed

    PanelWindow {
        id: win

        screen: Globals.popupScreen
        // No anchors = centered on screen
        // Extra room around the card so animations aren't cut off; only the card takes clicks
        readonly property int pad: 60
        implicitWidth: Config.launcher.width + pad * 2
        readonly property int heroH: Config.launcher.hero ? Config.launcher.heroHeight + 12 : 0
        implicitHeight: Config.launcher.height + heroH + pad * 2
        mask: Region { item: hitBox }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Globals.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-launcher"

        readonly property var apps: {
            const q = search.text.trim().toLowerCase();
            const all = DesktopEntries.applications.values.filter(a => !a.noDisplay);
            if (q === "")
                return all.sort((a, b) => a.name.localeCompare(b.name));

            // Score: name starts with > word in name starts with > name contains > other fields contain
            const score = a => {
                const name = a.name.toLowerCase();
                if (name.startsWith(q)) return 0;
                if (name.split(/\s+/).some(w => w.startsWith(q))) return 1;
                if (name.includes(q)) return 2;
                const extra = [a.genericName, a.comment, (a.keywords ?? []).join(" "), a.id]
                    .join(" ").toLowerCase();
                return extra.includes(q) ? 3 : -1;
            };
            return all.map(a => ({ a, s: score(a) }))
                .filter(x => x.s >= 0)
                .sort((x, y) => x.s - y.s || x.a.name.localeCompare(y.a.name))
                .map(x => x.a);
        }

        function launch(app) {
            if (!app) return;
            app.execute();
            Globals.launcherOpen = false;
        }

        // Current wallpaper on this monitor (for the banner)
        property string wall: ""
        Process {
            running: Config.launcher.hero
            command: ["sh", "-c", "awww query 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let first = "";
                    for (const line of text.split("\n")) {
                        const r = line.match(/^:?\s*([^:]+):.*image: (.+)$/);
                        if (!r) continue;
                        if (!first) first = r[2].trim();
                        if (r[1].trim() === win.screen?.name) { win.wall = r[2].trim(); return; }
                    }
                    win.wall = first;
                }
            }
        }
        SystemClock { id: clock; precision: SystemClock.Minutes }
        readonly property string greeting: {
            const h = clock.date.getHours();
            return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
        }

        HyprlandFocusGrab {
            active: Globals.launcherOpen
            windows: [win]
            onCleared: Globals.launcherOpen = false
        }

        // What takes clicks: the card's resting place. Not the card itself, which zooms in on
        // open; the click area was measured mid-zoom, so clicks near the card's edges (like
        // on the scrollbar) counted as "outside" and closed the panel.
        Item {
            id: hitBox
            anchors.fill: parent
            anchors.margins: win.pad
        }

        Rectangle {
            id: card
            anchors.fill: parent
            anchors.margins: win.pad
            opacity: loader.motion.opacityValue
            scale: loader.motion.scaleValue
            transform: Translate { y: loader.motion.offset }
            radius: 28
            // Same color and transparency as the bar (Settings → Bar)
            color: BarConfig.solidColor
            border.width: BarConfig.borderWidth > 0 ? BarConfig.borderWidth : 1
            border.color: BarConfig.borderWidth > 0 ? BarConfig.borderColor : Qt.rgba(Theme.fg1.r, Theme.fg1.g, Theme.fg1.b, 0.08)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // ── Hero: current wallpaper with the time and a greeting ──
                ClippingRectangle {
                    visible: Config.launcher.hero
                    Layout.fillWidth: true
                    Layout.preferredHeight: Config.launcher.heroHeight
                    radius: 20
                    color: Theme.bg1

                    Image {
                        id: wallImg
                        anchors.fill: parent
                        source: win.wall ? "file://" + win.wall : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 1280
                        opacity: status === Image.Ready ? 1 : 0
                        scale: status === Image.Ready ? 1 : 1.06
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                    // Darken the bottom so the text stays readable on any wallpaper
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.05) }
                            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.15) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                        }
                    }

                    ColumnLayout {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 18 }
                        spacing: 0
                        Text {
                            text: Config.bar.clock24h ? Qt.formatDateTime(clock.date, "HH:mm")
                                : Qt.formatDateTime(clock.date, "hh:mm AP").split(" ")[0]
                            color: "white"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 26
                            font.weight: Font.Bold
                            font.features: ({ tnum: 1 })
                        }
                        Text {
                            text: `${win.greeting}, ${Quickshell.env("USER")}`
                            color: Qt.rgba(1, 1, 1, 0.85)
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.Medium
                        }
                    }

                    // App count chip
                    Rectangle {
                        anchors { right: parent.right; top: parent.top; margins: 12 }
                        implicitHeight: 28
                        implicitWidth: chip.implicitWidth + 20
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.35)
                        Text {
                            id: chip
                            anchors.centerIn: parent
                            text: win.apps.length + (win.apps.length === 1 ? " app" : " apps")
                            color: "white"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.Medium
                        }
                    }
                }

                // ── Search field: accent outline and icon while focused, clear button ──
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 26
                    color: BarConfig.surface(Theme.bg1)
                    border.width: search.activeFocus ? 2 : 0
                    border.color: Theme.accent
                    Behavior on border.width { NumberAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 10
                        spacing: 12

                        Text {
                            text: "search"
                            color: search.activeFocus ? Theme.accent : Theme.fg2
                            Behavior on color { ColorAnimation { duration: 150 } }
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: Theme.fontSize + 6
                        }

                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            focus: true
                            color: Theme.fg1
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.bg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 3
                            font.weight: Font.Medium
                            onTextChanged: list.currentIndex = 0

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: "Search apps…"
                                color: Theme.fg2
                                font: search.font
                            }

                            Keys.onEscapePressed: search.text !== "" ? search.text = "" : Globals.launcherOpen = false
                            Keys.onReturnPressed: win.launch(win.apps[list.currentIndex])
                            Keys.onEnterPressed: win.launch(win.apps[list.currentIndex])
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onTabPressed: list.incrementCurrentIndex()
                        }

                        MIconButton {
                            icon: "close"
                            size: 34
                            opacity: search.text !== "" ? 1 : 0
                            scale: search.text !== "" ? 1 : 0.6
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            onClicked: { search.text = ""; search.forceActiveFocus(); }
                        }
                    }
                }

                ListView {
                    SmoothWheel { flick: list }
                    MScrollBar { flick: list }
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: win.apps
                    keyNavigationWraps: true
                    boundsBehavior: Flickable.StopAtBounds

                    // Selection pill glides between rows (Material emphasized easing)
                    highlightFollowsCurrentItem: false
                    highlight: Rectangle {
                        width: list.width - (list.contentHeight > list.height ? 12 : 0)
                        height: 56
                        y: list.currentItem?.y ?? 0
                        radius: 18
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                        visible: list.count > 0
                        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
                    }

                    // Rows flow in, slightly staggered, on open and as you type
                    populate: Transition {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.max(0, Math.min(ViewTransition.index, 10)) * 14 }
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                                NumberAnimation { property: "y"; from: ViewTransition.destination.y + 14; duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel }
                            }
                        }
                    }

                    delegate: Item {
                        id: entry
                        required property DesktopEntry modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem
                        width: ListView.view.width
                        height: 56

                        // Hover state layer
                        Rectangle {
                            anchors.fill: parent
                            radius: 18
                            color: Theme.fg1
                            opacity: rowArea.pressed ? 0.10 : rowArea.containsMouse && !entry.current ? 0.05 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 14
                            spacing: 14

                            // Icon in a tonal tile that lights up when selected
                            Rectangle {
                                implicitWidth: 40
                                implicitHeight: 40
                                radius: entry.current ? 14 : 20
                                color: entry.current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : BarConfig.surface(Theme.bg2)
                                Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 180 } }
                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 26
                                    scale: entry.current ? 1.08 : 1
                                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                                    source: Quickshell.iconPath(entry.modelData.icon, "application-x-executable")
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: entry.modelData.name
                                    color: entry.current ? Theme.accent : Theme.fg1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 1
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: Config.launcher.showDescriptions && text !== ""
                                    text: entry.modelData.comment || entry.modelData.genericName || ""
                                    color: Theme.fg2
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                    elide: Text.ElideRight
                                }
                            }

                            // "Enter" hint slides in on the selected row
                            Text {
                                text: "keyboard_return"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.variableAxes: Theme.iconAxes
                                font.pixelSize: Theme.fontSize + 2
                                opacity: entry.current ? 1 : 0
                                transform: Translate { x: entry.current ? 0 : -8 }
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = entry.index
                            onClicked: win.launch(entry.modelData)
                        }
                    }

                    // Nothing matches
                    Column {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        spacing: 8
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "search_off"; color: Theme.fg2; font.family: Theme.iconFont; font.variableAxes: Theme.iconAxes; font.pixelSize: 36 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: `No apps match "${search.text}"`; color: Theme.fg2; font.family: Theme.font; font.pixelSize: Theme.fontSize }
                    }
                }
            }
        }
    }
}

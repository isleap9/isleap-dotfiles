import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs

// App launcher (SUPER+A). Type to search, ↑/↓ to pick, Enter to launch, Esc to close.
LazyLoader {
    active: Globals.launcherOpen

    PanelWindow {
        id: win

        screen: Globals.popupScreen
        // No anchors = centered on screen
        implicitWidth: Config.launcher.width
        implicitHeight: Config.launcher.height
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
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

        HyprlandFocusGrab {
            active: true
            windows: [win]
            onCleared: Globals.launcherOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Theme.bg0
            border.color: Theme.bg3
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Search box
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 24
                    color: Theme.bg1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        Text {
                            text: "󰍉"
                            color: Theme.fg2
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fontSize + 4
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
                            font.weight: Font.Bold
                            onTextChanged: list.currentIndex = 0

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: "Search apps…"
                                color: Theme.fg2
                                font: search.font
                            }

                            Keys.onEscapePressed: Globals.launcherOpen = false
                            Keys.onReturnPressed: win.launch(win.apps[list.currentIndex])
                            Keys.onEnterPressed: win.launch(win.apps[list.currentIndex])
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onTabPressed: list.incrementCurrentIndex()
                        }
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: win.apps
                    highlightMoveDuration: 120
                    keyNavigationWraps: true

                    highlight: Rectangle {
                        radius: 16
                        color: Theme.bg3
                    }

                    delegate: Item {
                        id: entry
                        required property DesktopEntry modelData
                        required property int index
                        width: ListView.view.width
                        height: 52

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 14

                            IconImage {
                                implicitSize: 32
                                source: Quickshell.iconPath(entry.modelData.icon, "application-x-executable")
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: entry.modelData.name
                                    color: Theme.fg1
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 1
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: Config.launcher.showDescriptions && text !== ""
                                    text: entry.modelData.comment || entry.modelData.genericName || ""
                                    color: Theme.fg2
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = entry.index
                            onClicked: win.launch(entry.modelData)
                        }
                    }
                }
            }
        }
    }
}

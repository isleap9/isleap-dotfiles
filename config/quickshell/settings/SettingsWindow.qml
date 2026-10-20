import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// The Settings app: a normal window (SUPER+COMMA, the app launcher, or Control Center → Settings).
// Every change is saved to ~/.config/quickshell/config.json and applies immediately.
LazyLoader {
    active: Globals.settingsOpen

    FloatingWindow {
        id: win

        readonly property var pages: [
            { id: "appearance",    icon: "󰏘", title: "Appearance",    file: "AppearancePage.qml" },
            { id: "bar",           icon: "\u{F0C7B}", title: "Bar",   file: "BarPage.qml" },
            { id: "monitors",      icon: "󰍹", title: "Monitors",      file: "MonitorsPage.qml" },
            { id: "notifications", icon: "󰂚", title: "Notifications", file: "NotificationsPage.qml" },
            { id: "launcher",      icon: "󰀻", title: "Launcher & Power", file: "LauncherPage.qml" },
            { id: "wallpaper",     icon: "󰸉", title: "Wallpaper & Colors", file: "WallpaperPage.qml" },
            { id: "keybinds",      icon: "󰌌", title: "Keybinds",      file: "KeybindsPage.qml" },
            { id: "system",        icon: "󰒓", title: "System",        file: "SystemPage.qml" }
        ]
        readonly property var page: pages.find(p => p.id === Globals.settingsPage) ?? pages[0]

        title: "Quickshell Settings"
        implicitWidth: 1000
        implicitHeight: 720
        color: Theme.bg0

        onVisibleChanged: if (!visible) Globals.settingsOpen = false

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sidebar
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 240
                color: Theme.bg1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        Layout.bottomMargin: 14
                        Layout.leftMargin: 8
                        Layout.topMargin: 6
                        spacing: 10
                        Text {
                            text: "󰣇"
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: 26
                        }
                        Text {
                            text: "Settings"
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 6
                            font.weight: Font.Black
                        }
                    }

                    Repeater {
                        model: win.pages

                        Rectangle {
                            id: navItem
                            required property var modelData
                            readonly property bool active: win.page.id === modelData.id

                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: 22
                            color: active ? Theme.accent : area.containsMouse ? Theme.bg3 : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                spacing: 12
                                Text {
                                    Layout.preferredWidth: 22
                                    horizontalAlignment: Text.AlignHCenter
                                    text: navItem.modelData.icon
                                    color: navItem.active ? Theme.bg1 : Theme.fg1
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.fontSize + 3
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: navItem.modelData.title
                                    color: navItem.active ? Theme.bg1 : Theme.fg1
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Globals.settingsPage = navItem.modelData.id
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        text: "Changes are saved automatically"
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Page
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Text {
                    Layout.leftMargin: 28
                    Layout.topMargin: 22
                    text: win.page.title
                    color: Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 9
                    font.weight: Font.Black
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    source: win.page.file
                }
            }
        }

        // Esc closes the window
        Shortcut {
            sequence: "Escape"
            onActivated: Globals.settingsOpen = false
        }
    }
}

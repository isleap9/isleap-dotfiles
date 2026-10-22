import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

// The Settings app: a normal window (SUPER+COMMA, the app launcher, or Control Center → Settings).
// Every change is saved to ~/.config/quickshell/config.json and applies immediately.
LazyLoader {
    active: Globals.settingsOpen

    FloatingWindow {
        id: win

        readonly property var pages: [
            { id: "appearance",    icon: "palette", title: "Appearance",    file: "AppearancePage.qml" },
            { id: "bar",           icon: "toolbar", title: "Bar",   file: "BarPage.qml" },
            { id: "monitors",      icon: "monitor", title: "Monitors",      file: "MonitorsPage.qml" },
            { id: "notifications", icon: "notifications", title: "Notifications", file: "NotificationsPage.qml" },
            { id: "panels",        icon: "dashboard", title: "Panels & Icons", file: "PanelsPage.qml" },
            { id: "animations",    icon: "animation", title: "Animations", file: "AnimationsPage.qml" },
            { id: "desktop",       icon: "desktop_windows", title: "Desktop & Night light", file: "DesktopPage.qml" },
            { id: "launcher",      icon: "apps", title: "Launcher & Power", file: "LauncherPage.qml" },
            { id: "wallpaper",     icon: "wallpaper", title: "Wallpaper & Colors", file: "WallpaperPage.qml" },
            { id: "keybinds",      icon: "keyboard", title: "Keybinds",      file: "KeybindsPage.qml" },
            { id: "system",        icon: "settings", title: "System",        file: "SystemPage.qml" }
        ]
        readonly property var page: pages.find(p => p.id === Globals.settingsPage) ?? pages[0]

        title: "Quickshell Settings"
        implicitWidth: 1000
        implicitHeight: 720
        // Same see-through background as the bar and panels (Settings → Bar → Background opacity);
        // Hyprland blurs what's behind. Each region is painted once so the transparency doesn't stack.
        color: "transparent"

        onVisibleChanged: if (!visible) Globals.settingsOpen = false

        // Click outside to close. A focus grab (not focus tracking) so that with
        // follow_mouse the window doesn't close just because the pointer left it.
        HyprlandFocusGrab {
            windows: [win]
            active: win.visible
            onCleared: Globals.settingsOpen = false
        }

        // Main area background (right of the sidebar, full height)
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 240
            color: BarConfig.surface(Theme.bg0)
        }

        WindowTitleBar {
            id: titleBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            windowTitle: win.title
            sidebarWidth: 240
            sidebarColor: BarConfig.surface(Theme.bg1)
            color: "transparent"
            onCloseRequested: Globals.settingsOpen = false
        }

        RowLayout {
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            // Sidebar
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 240
                color: BarConfig.surface(Theme.bg1)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        Layout.bottomMargin: 14
                        Layout.leftMargin: 8
                        Layout.topMargin: 6
                        spacing: 10
                        ArchLogo {
                            size: 24
                            color: Theme.accent
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
                                    property real fill: navItem.active ? 1 : 0
                                    Behavior on fill { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    font.variableAxes: Theme.iconAxesWith(fill)
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

        WindowResizeHandles { active: !titleBar.maximized }

        // Esc closes the window
        Shortcut {
            sequence: "Escape"
            onActivated: Globals.settingsOpen = false
        }
    }
}

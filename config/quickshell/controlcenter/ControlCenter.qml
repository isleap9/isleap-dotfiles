import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.components

// Control center (SUPER+SHIFT+E). Replaces the rofi control center and its sub-menus.
// Esc / Backspace on an empty search goes back; Esc on the main page closes.
LazyLoader {
    id: loader

    // Open/close animation (Settings → Animations)
    property PanelMotion motion: PanelMotion { style: Config.animations.controlCenter; open: Globals.controlCenterOpen }
    active: motion.needed

    PanelWindow {
        id: win

        readonly property var pages: ({
            main:       { title: "Control Center", icon: "settings", file: "MainPage.qml" },
            barlayout:  { title: "Bar Layout",     icon: "toolbar", file: "BarLayoutPage.qml" },
            themes:     { title: "Theme Switcher", icon: "palette", file: "ThemesPage.qml" },
            dynamic:    { title: "Dynamic Theme",  icon: "contrast", file: "DynamicPage.qml" },
            clipboard:  { title: "Clipboard",      icon: "content_paste", file: "ClipboardPage.qml" },
            capture:    { title: "Capture",        icon: "photo_camera", file: "CapturePage.qml" },
            emoji:      { title: "Emoji",          icon: "mood", file: "EmojiPage.qml" },
            cheatsheet: { title: "Cheatsheet",     icon: "keyboard", file: "CheatsheetPage.qml" }
        })
        readonly property var page: pages[Globals.controlCenterPage] ?? pages.main

        function go(name) {
            Globals.controlCenterPage = pages[name] ? name : "main";
        }

        // Close first, then run (so screenshots etc. don't capture this window)
        function runAndClose(cmd) {
            Globals.controlCenterOpen = false;
            Globals.run(cmd);
        }

        screen: Globals.popupScreen
        // Extra room around the card so animations aren't cut off; only the card takes clicks
        readonly property int pad: 60
        implicitWidth: 640 + pad * 2
        implicitHeight: 600 + pad * 2
        mask: Region { item: card }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Globals.controlCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-control-center"

        HyprlandFocusGrab {
            active: Globals.controlCenterOpen
            windows: [win]
            onCleared: Globals.controlCenterOpen = false
        }

        Rectangle {
            id: card
            anchors.fill: parent
            anchors.margins: win.pad
            opacity: loader.motion.opacityValue
            scale: loader.motion.scaleValue
            transform: Translate { y: loader.motion.offset }
            radius: 24
            color: Theme.bg0
            border.color: Theme.bg3
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header: back button + page title
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        visible: Globals.controlCenterPage !== "main"
                        implicitWidth: 34; implicitHeight: 34; radius: 17
                        color: backArea.containsMouse ? Theme.bg3 : Theme.bg1
                        Text {
                            anchors.centerIn: parent
                            text: "arrow_back"
                            color: Theme.fg1
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: Theme.fontSize + 2
                        }
                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.go("main")
                        }
                    }

                    Text {
                        text: win.page.icon
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.variableAxes: Theme.iconAxes
                        font.pixelSize: Theme.fontSize + 6
                    }
                    Text {
                        Layout.fillWidth: true
                        text: win.page.title
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 5
                        font.weight: Font.Black
                    }
                }

                Loader {
                    id: loader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    source: win.page.file
                    onLoaded: {
                        item.cc = win;
                        item.focusSearch();
                    }
                }
            }
        }
    }
}

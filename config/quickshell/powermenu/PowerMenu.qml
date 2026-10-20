import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs

// Power menu (SUPER+M). ←/→ to pick, Enter to choose, Esc to close.
// Everything except Lock asks for confirmation first, like your old rofi menu.
LazyLoader {
    active: Globals.powerMenuOpen

    PanelWindow {
        id: win

        screen: Globals.popupScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Qt.rgba(0, 0, 0, 0.45)
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-powermenu"

        readonly property var actions: [
            { icon: "󰌾", label: "Lock",     confirm: false, cmd: "loginctl lock-session" },
            { icon: "󰒲", label: "Suspend",  confirm: true,  cmd: "systemctl suspend" },
            { icon: "󰍃", label: "Logout",   confirm: true,  cmd: "killall Hyprland" },
            { icon: "󰜉", label: "Reboot",   confirm: true,  cmd: "systemctl reboot" },
            { icon: "󰐥", label: "Shutdown", confirm: true,  cmd: "systemctl poweroff" }
        ]
        property int selected: 0
        property int confirming: -1   // index waiting for "are you sure?"
        property string uptime: ""

        function choose(i) {
            const a = actions[i];
            if (Config.powerMenu.confirm && a.confirm && confirming !== i) {
                confirming = i;
                selected = i;
                return;
            }
            Globals.powerMenuOpen = false;
            Globals.run(a.cmd);
        }

        Process {
            running: true
            command: ["uptime", "-p"]
            stdout: StdioCollector { onStreamFinished: win.uptime = text.trim().replace(/^up /, "") }
        }

        // Click on the dark background closes
        MouseArea {
            anchors.fill: parent
            onClicked: Globals.powerMenuOpen = false
        }

        Rectangle {
            anchors.centerIn: parent
            implicitWidth: layout.implicitWidth + 56
            implicitHeight: layout.implicitHeight + 48
            radius: 32
            color: Theme.bg0
            border.color: Theme.bg3
            border.width: 1

            focus: true
            Keys.onEscapePressed: win.confirming >= 0 ? win.confirming = -1 : Globals.powerMenuOpen = false
            Keys.onLeftPressed: { win.selected = (win.selected + 4) % 5; win.confirming = -1; }
            Keys.onRightPressed: { win.selected = (win.selected + 1) % 5; win.confirming = -1; }
            Keys.onReturnPressed: win.choose(win.selected)
            Keys.onEnterPressed: win.choose(win.selected)

            // Swallow clicks so they don't reach the background
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: layout
                anchors.centerIn: parent
                spacing: 20

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: win.confirming >= 0
                            ? `${win.actions[win.confirming].label}? Click again to confirm`
                            : `Goodbye ${Quickshell.env("USER")}`
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 7
                        font.weight: Font.Black
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: win.uptime ? `Uptime: ${win.uptime}` : ""
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                }

                RowLayout {
                    spacing: 14

                    Repeater {
                        model: win.actions

                        Rectangle {
                            id: btn
                            required property var modelData
                            required property int index
                            readonly property bool isSelected: win.selected === index
                            readonly property bool isConfirming: win.confirming === index

                            implicitWidth: 110
                            implicitHeight: 110
                            radius: 28
                            color: isConfirming ? Theme.red : isSelected ? Theme.accent : Theme.bg1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: btn.modelData.icon
                                color: btn.isSelected || btn.isConfirming ? Theme.bg1 : Theme.fg1
                                font.family: Theme.iconFont
                                font.pixelSize: 40
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: if (win.confirming !== btn.index) { win.selected = btn.index; win.confirming = -1; }
                                onClicked: win.choose(btn.index)
                            }
                        }
                    }
                }
            }
        }
    }
}

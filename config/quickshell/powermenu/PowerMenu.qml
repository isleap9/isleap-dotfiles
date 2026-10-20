import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

// Power menu (SUPER+M). ←/→ to pick, Enter to choose, Esc to close.
// Everything except Lock asks for confirmation first, like your old rofi menu.
LazyLoader {
    id: loader

    // Open/close animation (Settings → Animations)
    property PanelMotion motion: PanelMotion { style: Config.animations.powerMenu; open: Globals.powerMenuOpen }
    active: motion.needed

    PanelWindow {
        id: win

        screen: Globals.popupScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Qt.rgba(0, 0, 0, 0.45 * Math.min(1, Math.max(0, loader.motion.progress)))
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Globals.powerMenuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-powermenu"

        readonly property var actions: [
            { icon: "lock", label: "Lock",     confirm: false, cmd: "loginctl lock-session" },
            { icon: "bedtime", label: "Suspend",  confirm: true,  cmd: "systemctl suspend" },
            { icon: "logout", label: "Logout",   confirm: true,  cmd: "killall Hyprland" },
            { icon: "restart_alt", label: "Reboot",   confirm: true,  cmd: "systemctl reboot" },
            { icon: "power_settings_new", label: "Shutdown", confirm: true,  cmd: "systemctl poweroff" }
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
            opacity: loader.motion.opacityValue
            scale: loader.motion.scaleValue
            transform: Translate { y: loader.motion.offset }
            implicitWidth: layout.implicitWidth + 56
            implicitHeight: layout.implicitHeight + 48
            radius: 36
            // Same color and transparency as the bar
            color: BarConfig.solidColor
            border.width: BarConfig.borderWidth > 0 ? BarConfig.borderWidth : 1
            border.color: BarConfig.borderWidth > 0 ? BarConfig.borderColor : Qt.rgba(Theme.fg1.r, Theme.fg1.g, Theme.fg1.b, 0.08)
            Behavior on implicitWidth { NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }

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

                // ── Title: crossfades between the goodbye and "are you sure?" ──
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    implicitHeight: title.implicitHeight
                    Text {
                        id: title
                        anchors.horizontalCenter: parent.horizontalCenter
                        property string want: win.confirming >= 0
                            ? `${win.actions[win.confirming].label}? Click again to confirm`
                            : `Goodbye, ${Quickshell.env("USER")}`
                        text: want
                        color: win.confirming >= 0 ? Theme.red : Theme.fg1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 8
                        font.weight: Font.Bold
                        onWantChanged: swap.restart()
                        SequentialAnimation {
                            id: swap
                            NumberAnimation { target: title; property: "opacity"; to: 0; duration: 90 }
                            PropertyAction { target: title; property: "text"; value: title.want }
                            ParallelAnimation {
                                NumberAnimation { target: title; property: "opacity"; to: 1; duration: 180 }
                                NumberAnimation { target: titleShift; property: "y"; from: 6; to: 0; duration: 220; easing.type: Easing.OutCubic }
                            }
                        }
                        transform: Translate { id: titleShift }
                    }
                }

                // Uptime chip
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -8
                    visible: win.uptime !== ""
                    implicitHeight: 30
                    implicitWidth: upRow.implicitWidth + 24
                    radius: 15
                    color: BarConfig.surface(Theme.bg1)
                    Row {
                        id: upRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "schedule"; color: Theme.accent; font.family: Theme.iconFont; font.variableAxes: Theme.iconAxes; font.pixelSize: Theme.fontSize + 1 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: `Up ${win.uptime}`; color: Theme.fg2; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                    }
                }

                // ── Actions: the selected one morphs into a wide rounded tile with its label ──
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Repeater {
                        model: win.actions

                        Rectangle {
                            id: btn
                            required property var modelData
                            required property int index
                            readonly property bool isSelected: win.selected === index
                            readonly property bool isConfirming: win.confirming === index
                            readonly property bool lit: isSelected || isConfirming
                            readonly property color onColor: isConfirming ? Theme.bg0 : lit ? Theme.bg0 : Theme.fg1

                            implicitWidth: lit ? 150 : 96
                            implicitHeight: 96
                            radius: lit ? 28 : 48
                            color: isConfirming ? Theme.red : isSelected ? Theme.accent : BarConfig.surface(Theme.bg1)
                            Behavior on implicitWidth { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                            Behavior on radius { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                            scale: area.pressed ? 0.93 : 1
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            // Staggered pop-in when the menu opens
                            property real intro: 0
                            opacity: intro
                            transform: Translate { y: (1 - btn.intro) * 18 }
                            Component.onCompleted: introAnim.start()
                            SequentialAnimation {
                                id: introAnim
                                PauseAnimation { duration: 60 + btn.index * 45 }
                                NumberAnimation { target: btn; property: "intro"; to: 1; duration: Math.max(1, Theme.animMs * 1.2); easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                            }

                            // Gentle pulse while waiting for confirmation
                            SequentialAnimation on opacity {
                                running: btn.isConfirming
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.75; duration: 600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                                onStopped: btn.opacity = Qt.binding(() => btn.intro)
                            }

                            // Hover state layer
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: btn.onColor
                                opacity: area.containsMouse && !btn.lit ? 0.08 : 0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: btn.isConfirming ? "check" : btn.modelData.icon
                                    color: btn.onColor
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    font.family: Theme.iconFont
                                    font.variableAxes: Theme.iconAxesWith(btn.lit ? 1 : 0)
                                    font.pixelSize: 34
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: btn.isConfirming ? "Confirm" : btn.modelData.label
                                    color: btn.onColor
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                    font.weight: Font.DemiBold
                                    opacity: btn.lit ? 1 : 0
                                    height: btn.lit ? implicitHeight : 0
                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                }
                            }

                            MouseArea {
                                id: area
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

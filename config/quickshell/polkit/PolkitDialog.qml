import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs

// Password prompt for apps that need admin rights (polkit), Material 3 dialog.
// Replaces the KDE polkit agent. Enter = authenticate, Esc = cancel.
Scope {
    id: root

    PolkitAgent { id: agent }
    readonly property var flow: agent.flow

    LazyLoader {
        active: agent.isActive && root.flow !== null

        PanelWindow {
            id: win
            screen: Globals.focusedScreen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-polkit"

            readonly property var flow: root.flow
            property bool wrong: false

            Connections {
                target: win.flow
                function onAuthenticationFailed() { win.wrong = true; pw.text = ""; shake.start(); }
            }

            function submit() {
                if (!flow || pw.text === "") return;
                wrong = false;
                flow.submit(pw.text);
            }
            function cancel() { flow?.cancelAuthenticationRequest(); }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.55)
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Rectangle {
                id: dialog
                anchors.centerIn: parent
                width: 440
                height: col.implicitHeight + 48
                radius: 28
                color: Theme.bg1
                border.width: 1
                border.color: Theme.bg3
                scale: 0.92
                opacity: 0
                Component.onCompleted: { scale = 1; opacity = 1; pw.forceActiveFocus(); }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 180 } }
                transform: Translate { id: nudge }
                SequentialAnimation {
                    id: shake
                    loops: 2
                    NumberAnimation { target: nudge; property: "x"; to: -10; duration: 50 }
                    NumberAnimation { target: nudge; property: "x"; to: 10; duration: 80 }
                    NumberAnimation { target: nudge; property: "x"; to: 0; duration: 50 }
                }

                ColumnLayout {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24
                    spacing: 16

                    // Icon
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 56; implicitHeight: 56; radius: 28
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                        Text {
                            anchors.centerIn: parent
                            text: "shield_lock"
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: 28
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Authentication required"
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 7
                        font.weight: Font.Bold
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: win.flow?.message ?? ""
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }

                    // Who
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        Rectangle {
                            implicitWidth: 28; implicitHeight: 28; radius: 14
                            color: Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: "person"
                                color: Theme.bg0
                                font.family: Theme.iconFont
                                font.variableAxes: Theme.iconAxes
                                font.pixelSize: 16
                            }
                        }
                        Text {
                            text: win.flow?.selectedIdentity?.displayName ?? win.flow?.selectedIdentity?.name ?? Quickshell.env("USER")
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.Bold
                        }
                    }

                    // Password (outlined text field)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 56
                        radius: 16
                        color: "transparent"
                        border.width: pw.activeFocus ? 2 : 1
                        border.color: win.wrong ? Theme.red : pw.activeFocus ? Theme.accent : Theme.fg2

                        Text {
                            x: 14
                            y: -8
                            leftPadding: 4; rightPadding: 4
                            text: (win.flow?.inputPrompt ?? "Password").replace(/:\s*$/, "")
                            color: win.wrong ? Theme.red : Theme.accent
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 4
                            Rectangle { anchors.fill: parent; color: Theme.bg1; z: -1 }
                        }
                        TextInput {
                            id: pw
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: win.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                            enabled: win.flow?.isResponseRequired ?? false
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            onAccepted: win.submit()
                            Keys.onEscapePressed: win.cancel()
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        wrapMode: Text.Wrap
                        text: win.wrong ? "Wrong password, try again" : (win.flow?.supplementaryMessage ?? "")
                        color: win.wrong || win.flow?.supplementaryIsError ? Theme.red : Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                    }

                    // Buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 8
                        DialogButton { text: "Cancel"; onClicked: win.cancel() }
                        DialogButton { text: "Authenticate"; filled: true; enabled: pw.text !== ""; onClicked: win.submit() }
                    }
                }
            }
        }
    }
}

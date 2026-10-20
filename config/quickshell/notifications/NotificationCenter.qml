import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.components

// Side panel with all notifications (SUPER+N), Material 3 style. Esc or click outside closes.
// Slides in from the edge; cards animate in/out and can be swiped away to dismiss.
LazyLoader {
    id: loader

    // Open/close animation (Settings → Animations); "slide" comes in from the right edge
    property PanelMotion motion: PanelMotion { style: Config.animations.notifCenter; open: Globals.notifCenterOpen; distance: -60 }
    active: motion.needed

    PanelWindow {
        id: win

        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasized: [0.2, 0, 0, 1, 1, 1]

        screen: Globals.popupScreen
        anchors { top: true; right: true; bottom: true }
        margins { top: 8; right: Theme.barSideMargin; bottom: 16 }
        exclusiveZone: 0
        implicitWidth: 420
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Globals.notifCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-notification-center"

        HyprlandFocusGrab {
            active: Globals.notifCenterOpen
            windows: [win]
            onCleared: Globals.notifCenterOpen = false
        }

        Rectangle {
            id: panel
            width: parent.width
            height: parent.height
            radius: 28
            color: BarConfig.surface(Theme.bg0)
            focus: true
            Keys.onEscapePressed: Globals.notifCenterOpen = false

            transform: Translate { x: -loader.motion.offset }
            opacity: loader.motion.opacityValue
            scale: loader.motion.scaleValue
            transformOrigin: Item.TopRight

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                // ── Header: title + count badge, DND chip, clear all ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    spacing: 8

                    Text {
                        text: "Notifications"
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 6
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        visible: Notifs.count > 0
                        implicitHeight: 22
                        implicitWidth: Math.max(22, countText.implicitWidth + 12)
                        radius: 11
                        color: Theme.accent
                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: Notifs.count
                            color: Theme.bg0
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Font.Bold
                        }
                    }
                    Item { Layout.fillWidth: true }

                    MFilterChip {
                        icon: Notifs.dnd ? "notifications_off" : "do_not_disturb_on"
                        label: "Do not disturb"
                        selected: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                    MIconButton {
                        icon: "clear_all"
                        style: "tonal"
                        size: 36
                        enabled: Notifs.count > 0
                        onClicked: Notifs.clearAll()
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    boundsBehavior: Flickable.StopAtBounds
                    model: ScriptModel { values: Array.from(Notifs.list) }

                    delegate: Item {
                        id: slot
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: card.implicitHeight

                        property real enter: 1
                        property real leave: 0
                        property real dragX: 0
                        readonly property int exitSign: dragX < 0 ? -1 : 1

                        NotificationCard {
                            id: card
                            notif: slot.modelData
                            width: parent.width
                            transform: Translate {
                                x: slot.dragX + (1 - slot.enter) * 40 + slot.leave * slot.exitSign * (slot.width + 40)
                            }
                            opacity: slot.enter * (1 - slot.leave)
                                     * (1 - Math.min(Math.abs(slot.dragX) / slot.width, 1) * 0.6)
                        }

                        // Swipe sideways to dismiss
                        DragHandler {
                            target: null
                            yAxis.enabled: false
                            onTranslationChanged: if (active) slot.dragX = translation.x
                            onActiveChanged: {
                                if (active) { springBack.stop(); return; }
                                if (Math.abs(slot.dragX) > slot.width * 0.3 && slot.modelData)
                                    slot.modelData.dismiss();
                                else
                                    springBack.start();
                            }
                        }
                        NumberAnimation {
                            id: springBack
                            target: slot; property: "dragX"; to: 0
                            duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2
                        }

                        // Staggered entrance when the panel opens
                        Component.onCompleted: if (!list.ready) { enter = 0; enterAnim.start(); }
                        SequentialAnimation {
                            id: enterAnim
                            PauseAnimation { duration: Math.max(0, Math.min(slot.index, 8)) * 40 }
                            NumberAnimation {
                                target: slot; property: "enter"; to: 1
                                duration: Theme.animMs + 150
                                easing.type: Easing.BezierSpline; easing.bezierCurve: win.emphasizedDecel
                            }
                        }
                    }

                    // After the first layout, new cards use the add transition instead of the stagger
                    property bool ready: false
                    Component.onCompleted: Qt.callLater(() => ready = true)

                    add: Transition {
                        NumberAnimation {
                            property: "enter"; from: 0; to: 1
                            duration: Theme.animMs + 200
                            easing.type: Easing.BezierSpline; easing.bezierCurve: win.emphasizedDecel
                        }
                    }
                    remove: Transition {
                        NumberAnimation {
                            property: "leave"; to: 1
                            duration: Math.round(Theme.animMs * 0.7)
                            easing.type: Easing.BezierSpline; easing.bezierCurve: win.emphasizedAccel
                        }
                    }
                    displaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Theme.animMs + 150
                            easing.type: Easing.BezierSpline; easing.bezierCurve: win.emphasized
                        }
                        NumberAnimation { property: "enter"; to: 1; duration: Theme.animMs }
                    }
                }
            }

            // ── Empty state ──
            Column {
                anchors.centerIn: parent
                spacing: 12
                opacity: Notifs.count === 0 ? 1 : 0
                scale: Notifs.count === 0 ? 1 : 0.9
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.animMs } }
                Behavior on scale { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 88; height: 88; radius: 44
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                    CenteredIcon {
                        text: Notifs.dnd ? "notifications_off" : "notifications_active"
                        color: Theme.accent
                        size: 40
                        fill: 1
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "You're all caught up"
                    color: Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Font.Medium
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Notifs.dnd ? "Do not disturb is on" : "No new notifications"
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.components

// System tray. Left click: open app, right click: its menu.
Pill {
    bubble: false
    id: root

    required property var barWindow

    shown: SystemTray.items.values.length > 0
    interactive: false
    spacing: 0
    readonly property bool trayBubble: BarConfig.opt(settings, "bubble") !== false

    // The tray icons sit together in one tonal bubble (Material app-indicator group)
    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: icons.implicitWidth + (root.trayBubble ? 16 : 0)
        implicitHeight: Math.min(34, Theme.barHeight - 8)
        radius: height / 2
        color: root.trayBubble ? BarConfig.bubbleColor : "transparent"

    RowLayout {
        id: icons
        anchors.centerIn: parent
        spacing: 10

    Repeater {
        model: SystemTray.items

        IconImage {
            id: icon
            required property SystemTrayItem modelData

            Layout.alignment: Qt.AlignVCenter
            implicitSize: BarConfig.iconSize + 3
            source: modelData.icon

            // Material hover highlight
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 10
                height: width
                radius: width / 2
                color: root.textColor
                opacity: trayArea.pressed ? 0.16 : trayArea.containsMouse ? 0.08 : 0
                z: -1
            }

            MouseArea {
                id: trayArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => {
                    const item = icon.modelData;
                    if (m.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (m.button === Qt.RightButton || item.onlyMenu) {
                        // Our own Material menu instead of the app's Qt/GTK one
                        if (item.hasMenu) {
                            const same = Globals.trayMenuItem === item;
                            Globals.closeAll();
                            if (!same) {
                                Globals.trayMenuScreen = root.barWindow.screen;
                                Globals.trayMenuX = root.barWindow.screenX + icon.mapToItem(null, icon.width / 2, 0).x;
                                Globals.trayMenuItem = item;
                            }
                        }
                    } else {
                        item.activate();
                    }
                }
                onWheel: w => icon.modelData.scroll(w.angleDelta.y, false)
            }
        }
    }
    }
    }
}

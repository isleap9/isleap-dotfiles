import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.components

// System tray. Left click: open app, right click: its menu.
Pill {
    id: root

    required property var barWindow

    shown: Config.bar.modules.tray && SystemTray.items.values.length > 0
    interactive: false
    spacing: 10

    Repeater {
        model: SystemTray.items

        IconImage {
            id: icon
            required property SystemTrayItem modelData

            Layout.alignment: Qt.AlignVCenter
            implicitSize: 21
            source: modelData.icon

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => {
                    const item = icon.modelData;
                    if (m.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (m.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) {
                            const p = icon.mapToItem(null, 0, icon.height + 12);
                            item.display(root.barWindow, p.x, p.y);
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

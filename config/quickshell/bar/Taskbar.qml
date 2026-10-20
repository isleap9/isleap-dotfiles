import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs
import qs.components

// Open apps as icons (Material: the focused one gets an accent pill underneath).
// Click: focus (click the focused one again: minimize to the special workspace isn't a thing on
// Hyprland, so it just focuses). Middle click: close. Option: only this monitor's windows.
Pill {
    id: root

    property var screen: null
    readonly property bool thisMonitor: BarConfig.opt(settings, "monitor") !== false
    readonly property var monitorName: screen?.name ?? ""
    readonly property var windows: ToplevelManager.toplevels.values.filter(t =>
        !root.thisMonitor || (t.screens ?? []).some(s => s.name === root.monitorName))

    shown: windows.length > 0
    interactive: false
    spacing: 4

    Repeater {
        model: root.windows

        Item {
            id: app
            required property var modelData
            readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: BarConfig.iconSize + 14
            implicitHeight: Theme.barHeight - 6

            Rectangle {
                anchors.fill: parent
                radius: height / 3
                color: root.textColor
                opacity: area.containsMouse ? 0.12 : 0
            }
            IconImage {
                anchors.centerIn: parent
                implicitSize: BarConfig.iconSize + 4
                source: Globals.appIcon(app.modelData.appId)
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: app.modelData.activated ? 16 : 5
                height: 3
                radius: 1.5
                color: app.modelData.activated ? BarConfig.accentColor : root.textColor
                opacity: app.modelData.activated ? 1 : 0.4
                Behavior on width { NumberAnimation { duration: 150 } }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => m.button === Qt.MiddleButton ? app.modelData.close() : app.modelData.activate()
            }
            Tooltip {
                target: app
                show: area.containsMouse
                text: app.modelData.title || app.modelData.appId
            }
        }
    }
}

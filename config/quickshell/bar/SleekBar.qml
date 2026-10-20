import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// Waybar "sleek" layout: a solid bar attached to the top edge (at least 1000px wide,
// rounded bottom corners), plain-text modules, hour | workspaces | minutes in the middle.
PanelWindow {
    id: bar

    anchors.top: true
    implicitWidth: Math.max(1000, 2 * Math.max(left.implicitWidth, right.implicitWidth) + center.implicitWidth + 48)
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"

    // Background: bg0, square top corners, 10px bottom corners
    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.bg0
        Behavior on color { ColorAnimation { duration: Theme.animMs } }
        Rectangle {
            width: parent.width
            height: parent.radius
            color: parent.color
        }
    }

    RowLayout {
        id: left
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        ArchButton { flat: true }
        Volume { flat: true }
        Cava { flat: true; Layout.leftMargin: 12; Layout.rightMargin: 12 }
        Media { flat: true; maxTextWidth: 240 }
    }

    RowLayout {
        id: center
        anchors.centerIn: parent
        spacing: 0

        Clock {
            flat: true
            format: Config.bar.clock24h ? "HH" : "hh12"
            longFormat: "dddd, MMMM dd, yyyy"
            Layout.rightMargin: 15
            textItem.font.pixelSize: 18
            textItem.font.weight: Font.Bold
        }
        Workspaces { flat: true; screen: bar.screen; style: "sleek" }
        Clock {
            flat: true
            format: Config.bar.clock24h ? "mm" : "mm AP"
            longFormat: ""
            showCalendar: false
            Layout.leftMargin: 15
            textItem.font.pixelSize: 18
            textItem.font.weight: Font.Bold
        }
        Weather { flat: true }
    }

    RowLayout {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Tray { flat: true; barWindow: bar }
        Language { flat: true }
        Network { flat: true }
        NotifButton { flat: true }
        PowerButton { flat: true; Layout.leftMargin: 8 }
    }
}

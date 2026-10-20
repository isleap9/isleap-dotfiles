import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// Floating pill bar, 16px from the top. Layouts (from your Waybar configs):
//   default  — separate pills; left: arch, weather, clock, cava, media | workspaces | right: tray … power
//   default2 — like default without cava; right side shares one pill; classic workspaces
//   minimal  — everything in one centered pill
PanelWindow {
    id: bar

    property string layout: "default"

    anchors { top: true; left: true; right: true }
    margins.top: Theme.barMargin
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"

    Loader {
        anchors.fill: parent
        sourceComponent: bar.layout === "default2" ? default2
                       : bar.layout === "minimal" ? minimal
                       : defaultLayout
    }

    Component {
        id: defaultLayout
        Item {
            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: Theme.barSideMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing

                ArchButton {}
                Weather {}
                Clock {}
                Cava {}
                Media {}
            }

            Workspaces {
                anchors.centerIn: parent
                screen: bar.screen
            }

            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: Theme.barSideMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing

                Tray { barWindow: bar }
                Language {}
                Volume {}
                Network {}
                NotifButton {}
                PowerButton {}
            }
        }
    }

    Component {
        id: default2
        Item {
            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: Theme.barSideMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing

                ArchButton {}
                Weather {}
                Clock {}
                Media {}
            }

            Workspaces {
                anchors.centerIn: parent
                screen: bar.screen
                style: "classic"
            }

            Group {
                anchors.right: parent.right
                anchors.rightMargin: Theme.barSideMargin
                anchors.verticalCenter: parent.verticalCenter

                Tray { barWindow: bar }
                Language {}
                Volume {}
                Network {}
                NotifButton {}
                PowerButton {}
            }
        }
    }

    Component {
        id: minimal
        Item {
            Group {
                anchors.centerIn: parent
                padding: 8

                ArchButton { Layout.leftMargin: 8 }
                Weather {}
                Clock {}
                Workspaces { screen: bar.screen; style: "classic" }
                Media {}
                Tray { barWindow: bar }
                Language {}
                Volume {}
                Network {}
                NotifButton {}
                PowerButton { Layout.leftMargin: 8; Layout.rightMargin: 8 }
            }
        }
    }
}

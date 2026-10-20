import QtQuick
import QtQuick.Layouts
import qs

// Material 3 quick-settings tile (like Android 14+): icon in a round badge, label, status line.
// On = filled with the accent color. Click the tile to toggle; the chevron (if `hasMore`) opens details.
Rectangle {
    id: root

    property string icon
    property string label
    property string status: ""
    property bool on: false
    property bool available: true
    property bool hasMore: false
    signal toggled
    signal more

    readonly property color fg: on ? Theme.bg0 : Theme.fg1

    implicitHeight: 64
    radius: on ? 20 : 32
    color: on ? Theme.accent : BarConfig.surface(Theme.bg2)
    opacity: available ? 1 : 0.45
    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 180 } }

    // Hover / press state layer
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.fg
        opacity: area.pressed ? 0.12 : area.containsMouse ? 0.06 : 0
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.available) root.toggled()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: root.hasMore ? 4 : 14
        spacing: 10

        Rectangle {
            implicitWidth: 44
            implicitHeight: 44
            radius: 22
            color: root.on ? Qt.rgba(0, 0, 0, 0.12) : Theme.bg3
            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.fg
                font.family: Theme.iconFont
                property real fill: root.on ? 1 : 0
                Behavior on fill { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                font.variableAxes: Theme.iconAxesWith(fill)
                font.pixelSize: 21
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                color: root.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.status
                elide: Text.ElideRight
                color: root.fg
                opacity: 0.75
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }
        Rectangle {
            visible: root.hasMore
            implicitWidth: 36
            implicitHeight: 52
            radius: 18
            color: moreArea.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : "transparent"
            Text {
                anchors.centerIn: parent
                text: "chevron_right"
                color: root.fg
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxes
                font.pixelSize: 20
            }
            MouseArea {
                id: moreArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.available) root.more()
            }
        }
    }
}

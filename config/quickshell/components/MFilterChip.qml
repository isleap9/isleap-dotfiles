import QtQuick
import QtQuick.Layouts
import qs

// M3 filter chip: outlined when off, tonal accent with a check when selected
Rectangle {
    id: chip

    property string icon
    property string label
    property bool selected: false
    signal clicked

    implicitHeight: 34
    implicitWidth: chipRow.implicitWidth + 24
    radius: chipArea.pressed ? 10 : 17
    Behavior on radius { NumberAnimation { duration: 120 } }
    color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : "transparent"
    border.width: selected ? 0 : 1
    border.color: Theme.bg3
    Behavior on color { ColorAnimation { duration: 150 } }

    // State layer
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: chip.selected ? Theme.accent : Theme.fg1
        opacity: chipArea.pressed ? 0.12 : chipArea.containsMouse ? 0.08 : 0
    }

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: chip.selected ? "check" : chip.icon
            color: chip.selected ? Theme.accent : Theme.fg2
            font.family: Theme.iconFont
            font.variableAxes: Theme.iconAxes
            font.pixelSize: Theme.fontSize + 2
        }
        Text {
            text: chip.label
            color: chip.selected ? Theme.accent : Theme.fg1
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: chipArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}

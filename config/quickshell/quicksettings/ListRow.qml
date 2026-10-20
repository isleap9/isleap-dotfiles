import QtQuick
import QtQuick.Layouts
import qs

// One row in a Material list: leading icon, title + subtitle, trailing content
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle: ""
    property bool selected: false
    property bool clickable: true
    default property alias trailing: slot.data
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 56
    radius: 16
    color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
        : area.containsMouse && clickable ? Theme.bg2 : "transparent"

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 14
        Text {
            text: root.icon
            color: root.selected ? Theme.accent : Theme.fg1
            font.family: Theme.iconFont
            font.variableAxes: Theme.iconAxes
            font.pixelSize: 22
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: root.selected ? Font.Bold : Font.Medium
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: root.selected ? Theme.accent : Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }
        Item {
            id: slot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}

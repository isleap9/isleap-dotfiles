import QtQuick
import QtQuick.Layouts
import qs

// A titled card that groups settings rows
ColumnLayout {
    id: root

    property string title
    property string description: ""
    default property alias content: card.data

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: root.title
        color: Theme.fg1
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        font.weight: Font.Black
    }
    Text {
        Layout.fillWidth: true
        visible: root.description !== ""
        text: root.description
        color: Theme.fg2
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
        wrapMode: Text.Wrap
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight + 8
        radius: 18
        color: Theme.bg1

        ColumnLayout {
            id: card
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            spacing: 0
        }
    }
}

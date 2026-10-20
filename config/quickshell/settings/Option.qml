import QtQuick
import QtQuick.Layouts
import qs

// One setting: label (+ optional description) on the left, a control on the right
Item {
    id: root

    property string label
    property string description: ""
    property string icon: ""
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(56, row.implicitHeight + 20)

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        spacing: 14

        Text {
            visible: root.icon !== ""
            Layout.preferredWidth: 24
            horizontalAlignment: Text.AlignHCenter
            text: root.icon
            color: Theme.fg1
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontSize + 4
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: root.label
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
                wrapMode: Text.Wrap
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
        }

        Item {
            id: slot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}

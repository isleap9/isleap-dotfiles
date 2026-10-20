import QtQuick
import qs

// Single-line text setting. Saves on Enter or when you click away.
Rectangle {
    id: root

    property string text
    property string placeholder: ""
    property bool valid: true
    signal accepted(string value)

    implicitWidth: 240
    implicitHeight: 34
    radius: 17
    color: Theme.bg2
    border.width: input.activeFocus ? 2 : 0
    border.color: valid ? Theme.accent : Theme.red

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        text: root.text
        clip: true
        color: Theme.fg1
        selectionColor: Theme.accent
        selectedTextColor: Theme.bg1
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        onEditingFinished: if (text !== root.text) root.accepted(text)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: Theme.fg2
            font: input.font
        }
    }
}

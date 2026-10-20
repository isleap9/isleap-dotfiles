import QtQuick
import qs

// Material 3 dialog button: text (accent) or filled
Rectangle {
    id: btn
    property string text
    property bool filled: false
    signal clicked
    implicitWidth: label.implicitWidth + 48
    implicitHeight: 40
    radius: 20
    opacity: enabled ? 1 : 0.4
    color: filled ? Theme.accent : "transparent"
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: btn.filled ? Theme.bg0 : Theme.accent
        opacity: area.pressed ? 0.16 : area.containsMouse ? 0.1 : 0
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: btn.filled ? Theme.bg0 : Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        font.weight: Font.Bold
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (btn.enabled) btn.clicked()
    }
}

import QtQuick
import qs

// Round button for the bar's Now playing widget. filled = accent (play/pause)
Rectangle {
    id: btn

    property string icon
    property bool filled: false
    property color tint: Theme.fg1
    property int size: 26
    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: width / 2
    opacity: enabled ? 1 : 0.35
    color: filled ? BarConfig.accentColor : area.containsMouse ? Qt.rgba(tint.r, tint.g, tint.b, 0.15) : "transparent"
    scale: area.pressed ? 0.9 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Text {
        anchors.centerIn: parent
        text: btn.icon
        color: btn.filled ? Theme.bg0 : btn.tint
        font.family: Theme.iconFont
        font.pixelSize: Math.round(btn.width * 0.55)
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (btn.enabled) btn.clicked()
    }
}

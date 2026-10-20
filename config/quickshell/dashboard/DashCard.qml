import QtQuick
import qs

// A card on the dashboard. Optional header (icon + title); content goes inside.
// Cards size themselves to the grid cell, so content should adapt to width/height.
Rectangle {
    id: card

    property string title: ""
    property string icon: ""
    property bool clickable: false
    default property alias content: body.data
    readonly property alias hovered: hover.hovered
    readonly property bool compact: width < 200 || height < 120
    readonly property int pad: compact ? 12 : 16
    signal clicked

    radius: 18
    color: clickable && hover.hovered ? Theme.bg2 : Theme.bg1
    Behavior on color { ColorAnimation { duration: 120 } }

    HoverHandler { id: hover }
    TapHandler {
        enabled: card.clickable
        onTapped: card.clicked()
    }

    Row {
        id: header
        visible: card.title !== ""
        x: card.pad
        y: card.pad - 2
        spacing: 8
        Text {
            visible: card.icon !== ""
            text: card.icon
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontSize + 1
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: card.title
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: card.pad
        anchors.topMargin: header.visible ? header.y + header.height + 8 : card.pad
    }
}

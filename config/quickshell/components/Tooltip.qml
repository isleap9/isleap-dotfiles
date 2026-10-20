import QtQuick
import Quickshell
import qs

// Popup that appears under a bar item while it is hovered.
// Put any content inside; or just set `text`.
PopupWindow {
    id: tip

    required property Item target
    property bool show: false
    property string text: ""
    property int delay: 400
    default property alias content: box.data

    anchor.item: target
    anchor.rect.x: target.width / 2
    anchor.rect.y: target.height + 8
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Bottom

    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight
    color: "transparent"
    visible: false

    Timer {
        id: delayTimer
        interval: tip.delay
        onTriggered: tip.visible = true
    }

    onShowChanged: {
        if (show) delayTimer.restart();
        else { delayTimer.stop(); visible = false; }
    }

    Rectangle {
        id: bg
        implicitWidth: box.childrenRect.width + 24
        implicitHeight: box.childrenRect.height + 20
        width: implicitWidth
        height: implicitHeight
        radius: 12
        color: Theme.bg0
        border.color: Theme.bg3
        border.width: 1

        Item {
            id: box
            x: 12
            y: 10

            Text {
                visible: tip.text !== ""
                text: tip.text
                color: Theme.fg1
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontSize
            }
        }
    }
}

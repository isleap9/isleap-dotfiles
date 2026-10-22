import QtQuick
import qs

// Material scrollbar for a Flickable: a slim pill at the right edge that widens on hover and
// can be dragged. Fades in while hovering the view or scrolling. Put it inside the view:
//   MScrollBar { flick: myList }
Item {
    id: bar

    property Flickable flick
    readonly property bool needed: flick && flick.contentHeight > flick.height + 1
    readonly property bool hot: area.containsMouse || area.pressed

    parent: flick
    anchors.right: parent ? parent.right : undefined
    anchors.top: parent ? parent.top : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.margins: 2
    width: 12
    visible: needed
    z: 10

    // Show while the view is hovered or moving. The hover detector sits on the view itself:
    // an item laid over the view would steal hover from the rows (launcher highlight, etc.)
    HoverHandler { id: viewHover; parent: bar.flick }
    property bool recent: false
    Timer { id: settle; interval: 900; onTriggered: bar.recent = false }
    Connections {
        target: bar.flick
        function onContentYChanged() { bar.recent = true; settle.restart(); }
    }
    opacity: hot || recent || viewHover.hovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 250 } }

    Rectangle {
        id: thumb
        anchors.right: parent.right
        width: bar.hot ? 8 : 4
        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        radius: width / 2
        color: bar.hot ? Theme.accent : Theme.fg2
        opacity: bar.hot ? 0.9 : 0.5
        Behavior on color { ColorAnimation { duration: 150 } }
        height: bar.flick ? Math.max(28, bar.flick.visibleArea.heightRatio * bar.height) : 0
        y: bar.flick ? Math.max(0, Math.min(bar.height - height,
            bar.flick.visibleArea.yPosition * bar.height)) : 0
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        property real grabOffset: 0
        function scrollTo(y) {
            const f = bar.flick;
            const ratio = Math.max(0, Math.min(1, (y - grabOffset) / Math.max(1, bar.height - thumb.height)));
            const minY = f.originY - f.topMargin;
            const maxY = Math.max(minY, f.originY + f.contentHeight + f.bottomMargin - f.height);
            f.contentY = minY + ratio * (maxY - minY);
        }
        onPressed: m => {
            // Grab the thumb where it was clicked; clicking the track jumps there
            grabOffset = m.y >= thumb.y && m.y <= thumb.y + thumb.height ? m.y - thumb.y : thumb.height / 2;
            scrollTo(m.y);
        }
        onPositionChanged: m => { if (pressed) scrollTo(m.y); }
    }
}

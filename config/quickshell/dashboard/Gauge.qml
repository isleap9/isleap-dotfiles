import QtQuick
import qs

// Ring gauge (0–1) with something in the middle (e.g. an icon)
Item {
    id: root

    property real value: 0
    property color color: Theme.accent
    property color track: Theme.bg3
    property real thickness: Math.max(3, width / 9)
    default property alias content: middle.data

    implicitWidth: 48
    implicitHeight: 48

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    onShownChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onTrackChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            const r = Math.min(width, height) / 2 - root.thickness / 2;
            const start = Math.PI * 0.75, sweep = Math.PI * 1.5;
            ctx.reset();
            ctx.lineCap = "round";
            ctx.lineWidth = root.thickness;
            ctx.strokeStyle = root.track;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r, start, start + sweep);
            ctx.stroke();
            if (root.shown > 0.005) {
                ctx.strokeStyle = root.color;
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, r, start, start + sweep * root.shown);
                ctx.stroke();
            }
        }
    }

    Item {
        id: middle
        anchors.fill: parent
    }
}

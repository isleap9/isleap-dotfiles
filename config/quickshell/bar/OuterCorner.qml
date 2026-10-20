import QtQuick

// A concave corner that blends the solid bar into the screen edge.
// Drawn as the top-left case (filled corner, curve towards the bottom-right); flip it for the others.
Canvas {
    id: root

    property color color
    property bool flipX: false
    property bool flipY: false

    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        const r = width;
        ctx.reset();
        ctx.save();
        ctx.translate(flipX ? r : 0, flipY ? r : 0);
        ctx.scale(flipX ? -1 : 1, flipY ? -1 : 1);
        ctx.fillStyle = root.color;
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(r, 0);
        ctx.arc(r, r, r, -Math.PI / 2, Math.PI, true);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
    }
}

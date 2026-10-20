import QtQuick
import qs

// Small line graph of recent values, with a soft fill underneath
Canvas {
    id: root

    property var values: []
    property real maximum: 100          // 0 = scale to the highest value
    property color color: Theme.accent

    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const v = values;
        if (v.length < 2) return;
        const max = maximum > 0 ? maximum : Math.max(1, ...v) * 1.15;
        const step = width / (v.length - 1);
        const y = val => height - 2 - (Math.min(val, max) / max) * (height - 4);
        ctx.beginPath();
        ctx.moveTo(0, y(v[0]));
        for (let i = 1; i < v.length; i++) {
            // Smooth curve through the midpoints
            const x0 = (i - 1) * step, x1 = i * step;
            ctx.bezierCurveTo((x0 + x1) / 2, y(v[i - 1]), (x0 + x1) / 2, y(v[i]), x1, y(v[i]));
        }
        ctx.lineWidth = 2;
        ctx.strokeStyle = color;
        ctx.stroke();
        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        const g = ctx.createLinearGradient(0, 0, 0, height);
        g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.35));
        g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0));
        ctx.fillStyle = g;
        ctx.fill();
    }
}

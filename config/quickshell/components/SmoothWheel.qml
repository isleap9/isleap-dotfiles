import QtQuick
import qs

// Smooth mouse-wheel scrolling for any Flickable / ListView / GridView. Put it inside the view:
//   SmoothWheel { flick: myList }
// A mouse wheel glides (one notch = 120 px); a touchpad scrolls 1:1. Handles the wheel before
// the view's own (Qt's default is slow and jumpy on Wayland).
WheelHandler {
    id: h

    property Flickable flick
    property real step: 120

    target: null
    acceptedModifiers: Qt.NoModifier
    enabled: flick && flick.contentHeight > flick.height

    readonly property real minY: flick ? flick.originY - flick.topMargin : 0
    readonly property real maxY: flick ? Math.max(minY, flick.originY + flick.contentHeight + flick.bottomMargin - flick.height) : 0

    onWheel: e => {
        const touchpad = e.pixelDelta.y !== 0;
        const dy = touchpad ? e.pixelDelta.y : e.angleDelta.y / 120 * step;
        if (dy === 0) return;
        const from = anim.running ? anim.to : flick.contentY;
        const to = Math.max(minY, Math.min(maxY, from - dy));
        anim.stop();
        if (touchpad || Theme.animMs === 0) flick.contentY = to;
        else {
            anim.to = to;
            anim.start();
        }
    }

    property NumberAnimation anim: NumberAnimation {
        target: h.flick
        property: "contentY"
        duration: 240
        easing.type: Easing.OutCubic
    }
}

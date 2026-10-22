import QtQuick
import qs

// Smooth mouse-wheel scrolling for any Flickable / ListView / GridView. Put it inside the view:
//   SmoothWheel { flick: myList }
// A mouse wheel glides (one notch = 120 px); a touchpad scrolls 1:1. Ctrl+wheel is left alone.
// It's a MouseArea laid over the view (buttons pass through): WheelHandler doesn't get events
// from some mice on Wayland, MouseArea gets every wheel event.
MouseArea {
    id: h

    property Flickable flick
    property real step: 120

    parent: flick
    anchors.fill: parent
    z: 100
    acceptedButtons: Qt.NoButton
    enabled: !!flick && flick.contentHeight > flick.height

    function scroll(wheel) {
        const touchpad = wheel.pixelDelta.y !== 0;
        const dy = touchpad ? wheel.pixelDelta.y : wheel.angleDelta.y / 120 * step;
        if (dy === 0) return;
        const minY = flick.originY - flick.topMargin;
        const maxY = Math.max(minY, flick.originY + flick.contentHeight + flick.bottomMargin - flick.height);
        const from = anim.running ? anim.to : flick.contentY;
        const to = Math.max(minY, Math.min(maxY, from - dy));
        anim.stop();
        if (touchpad || Theme.animMs === 0) flick.contentY = to;
        else {
            anim.to = to;
            anim.start();
        }
    }

    onWheel: wheel => {
        if (wheel.modifiers & Qt.ControlModifier) { wheel.accepted = false; return; }
        scroll(wheel);
    }

    NumberAnimation {
        id: anim
        target: h.flick
        property: "contentY"
        duration: 240
        easing.type: Easing.OutCubic
    }
}

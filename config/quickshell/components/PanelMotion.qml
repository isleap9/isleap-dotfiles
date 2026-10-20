import QtQuick
import qs

// Drives a panel's open/close animation in the style picked in Settings → Animations.
// Put it on the panel's LazyLoader as a property (a plain child would become the
// loader's component):
//     property PanelMotion motion: PanelMotion { style: Config.animations.dashboard; open: Globals.dashboardOpen }
//     active: motion.needed
// and bind the panel's content to motion.opacityValue / scaleValue / offset.
Item {
    id: root

    property string style: "slide"
    property bool open: false
    // Signed travel distance for "slide" (negative = comes down from above)
    property real distance: -40

    property real progress: 0
    // Keep the panel loaded while it's open or still animating closed
    readonly property bool needed: open || progress > 0

    readonly property real opacityValue: Motion.opacity(style, progress)
    readonly property real scaleValue: Motion.scale(style, progress)
    readonly property real offset: Motion.offset(style, progress, distance)

    onOpenChanged: run()
    Component.onCompleted: if (open) run()

    function run() {
        anim.stop();
        const ms = open ? Motion.openMs(style) : Motion.closeMs(style);
        if (ms <= 0) { progress = open ? 1 : 0; return; }
        anim.to = open ? 1 : 0;
        anim.duration = ms;
        if (open && style === "bounce") {
            anim.easing.type = Easing.OutBack;
            anim.easing.overshoot = 1.4;
        } else if (open && (style === "slide" || style === "scale")) {
            anim.easing.type = Easing.BezierSpline;
            anim.easing.bezierCurve = Motion.emphasizedDecel;
        } else {
            anim.easing.type = open ? Easing.OutCubic : Easing.InCubic;
        }
        // Opening: wait a frame so the freshly loaded panel has its size
        if (open) Qt.callLater(() => { if (root.open) anim.start(); });
        else anim.start();
    }

    NumberAnimation { id: anim; target: root; property: "progress" }
}

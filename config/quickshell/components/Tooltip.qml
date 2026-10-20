import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Hover card for a bar widget (Material 3). Put any content inside, or just set `text`.
// It's its own panel (layer "quickshell-hovercard"), so it gets the same frosted x-ray blur as the
// bar and matches it exactly. With a one-piece bar it drops out of the bar itself: same color,
// square where it meets the bar, curved joints, flush with the bar's ends. With pills it floats
// just below the widget. Clicks and hover go straight through it.
PanelWindow {
    id: tip

    required property Item target
    property bool show: false
    property string text: ""
    property int delay: Config.panels.hoverDelay
    default property alias content: box.data

    readonly property var barWin: target?.QsWindow?.window ?? null
    readonly property bool attached: BarConfig.solid
    readonly property bool atBottom: BarConfig.bottom
    readonly property int r: Math.round(Config.panels.joint * 0.75)
    readonly property color fill: attached ? BarConfig.solidColor : BarConfig.surface(Theme.bg1)

    // Where the card goes, worked out when it opens: x on the screen, centered under the widget
    // but never past the bar's ends; at an end it's flush with the bar (that bar corner squared)
    property real screenX: 0
    property bool flushLeft: false
    property bool flushRight: false
    readonly property int leftCorner: attached && !flushLeft ? r : 0
    readonly property int rightCorner: attached && !flushRight ? r : 0
    property string joinKey: ""
    function measure() {
        const win = barWin;
        if (!win) return;
        const p = target.mapToItem(null, 0, 0);
        const barStart = win.screenX ?? 0;                       // bar window's x on its screen
        const inset = win.cornersBeside ? win.r : 0;             // outer corners sit beside the bar
        const barLeft = barStart + inset;
        const barRight = barStart + win.width - inset;
        const full = card.width + (attached ? 2 * r : 0);
        let x = barStart + p.x + target.width / 2 - full / 2;
        flushLeft = attached && x < barLeft;
        flushRight = attached && !flushLeft && x + full > barRight;
        const w = card.width + (attached && !flushLeft ? r : 0) + (attached && !flushRight ? r : 0);
        if (flushLeft) x = barLeft;
        else if (flushRight) x = barRight - w;
        else if (!attached) x = Math.max(8, Math.min((screen?.width ?? 0) - w - 8, x));
        screenX = x;
        joinKey = (flushLeft || flushRight) && win.screen ? `${win.screen.name}:${flushLeft ? "left" : "right"}` : "";
    }

    property bool open: false
    Timer {
        id: delayTimer
        interval: tip.delay
        onTriggered: {
            tip.measure();
            tip.open = true;
            slide.y = tip.attached ? (tip.atBottom ? 1 : -1) * card.height : (tip.atBottom ? 8 : -8);
            sheet.opacity = 0;
            anim.restart();
        }
    }
    onShowChanged: {
        if (show && Config.panels.hoverCards) delayTimer.restart();
        else { delayTimer.stop(); open = false; }
    }
    onOpenChanged: {
        if (open && joinKey) Globals.barJoin = joinKey;
        else if (!open && joinKey && Globals.barJoin === joinKey) Globals.barJoin = "";
    }

    visible: open
    screen: barWin?.screen ?? null
    anchors.top: !atBottom
    anchors.bottom: atBottom
    anchors.left: true
    // Placed just past the bar's reserved space; floating pills get a small gap
    exclusiveZone: 0
    margins.top: atBottom ? 0 : (attached ? 0 : 8)
    margins.bottom: atBottom ? (attached ? 0 : 8) : 0
    margins.left: screenX
    implicitWidth: card.width + leftCorner + rightCorner
    implicitHeight: card.height
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-hovercard"
    mask: Region {}

    // Curved joints into the bar
    MCorner {
        visible: tip.leftCorner > 0
        width: tip.r; height: tip.r
        y: tip.atBottom ? parent.height - tip.r : 0
        flipX: true; flipY: tip.atBottom
        color: tip.fill
    }
    MCorner {
        visible: tip.rightCorner > 0
        width: tip.r; height: tip.r
        x: parent.width - tip.r
        y: tip.atBottom ? parent.height - tip.r : 0
        flipY: tip.atBottom
        color: tip.fill
    }

    Item {
        id: card
        x: tip.leftCorner
        width: box.childrenRect.width + 32
        height: box.childrenRect.height + 28
        clip: true

        Item {
            id: sheet
            width: parent.width
            height: parent.height
            transform: Translate { id: slide }
            ParallelAnimation {
                id: anim
                NumberAnimation { target: slide; property: "y"; to: 0; duration: Theme.animMs; easing.type: Easing.OutCubic }
                NumberAnimation { target: sheet; property: "opacity"; to: 1; duration: Theme.animMs * 0.6 }
            }

            Rectangle {
                readonly property int overhang: tip.attached ? radius : 0
                width: parent.width
                y: tip.atBottom ? 0 : -overhang
                height: parent.height + overhang
                radius: 20
                // Flush with the bar's end: square on that side where it meets the bar
                topLeftRadius: tip.flushLeft && !tip.atBottom ? 0 : radius
                topRightRadius: tip.flushRight && !tip.atBottom ? 0 : radius
                bottomLeftRadius: tip.flushLeft && tip.atBottom ? 0 : radius
                bottomRightRadius: tip.flushRight && tip.atBottom ? 0 : radius
                color: tip.fill
                border.width: tip.attached ? 0 : 1
                border.color: Theme.bg3
            }

            Item {
                id: box
                x: 16
                y: 14

                Text {
                    visible: tip.text !== ""
                    text: tip.text
                    color: Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    lineHeight: 1.15
                }
            }
        }
    }
}

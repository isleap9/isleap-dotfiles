import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// The bar on one monitor. Style (Settings → Bar):
//   floating — full width, transparent, widgets in pills, a gap from the screen edge
//   solid    — one background; fits around the widgets (at least 1000px) or spans the screen.
//              Touching the edge, it's square on that side (optionally with curved outer corners);
//              with a gap, it's rounded all round.
PanelWindow {
    id: bar

    readonly property bool solid: BarConfig.solid
    readonly property bool atBottom: BarConfig.bottom
    readonly property bool full: BarConfig.solidFull
    readonly property bool attached: solid && BarConfig.solidGap === 0
    readonly property int edgeGap: solid ? BarConfig.solidGap : Theme.barMargin
    readonly property int r: BarConfig.barRadius
    // Outer corners: beside the bar (fit width) or under its ends (full width)
    readonly property bool cornersBeside: BarConfig.outerCorners && !full && r > 0
    readonly property bool cornersBelow: BarConfig.outerCorners && full && r > 0

    anchors.top: !atBottom
    anchors.bottom: atBottom
    anchors.left: !solid || full
    anchors.right: !solid || full
    margins.top: atBottom ? 0 : edgeGap
    margins.bottom: atBottom ? edgeGap : 0
    margins.left: full && !attached ? Theme.barSideMargin : 0
    margins.right: full && !attached ? Theme.barSideMargin : 0

    implicitWidth: Math.max(1000, 2 * Math.max(left.implicitWidth, right.implicitWidth) + center.implicitWidth + 48)
        + (cornersBeside ? 2 * r : 0)
    implicitHeight: Theme.barHeight + (cornersBelow ? r : 0)
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"

    // Where the bar starts on its screen (to place popouts under a widget)
    readonly property real screenX: solid && !full ? ((screen?.width ?? 0) - width) / 2 : 0

    // Popouts line up with the bar's width
    // The bar's own width (without the outer corners beside it)
    readonly property real bodyWidth: width - (cornersBeside ? 2 * r : 0)
    onBodyWidthChanged: reportWidth()
    function reportWidth() {
        const w = Object.assign({}, Globals.barWidths);
        w[screen.name] = bodyWidth;
        Globals.barWidths = w;
    }

    // Keep awake (quick settings): no screen blanking or locking while on
    IdleInhibitor {
        window: bar
        enabled: Globals.keepAwake
    }
    // With corners under the bar, only reserve the bar itself, and let clicks through the corners
    function updateZone() { if (cornersBelow) exclusiveZone = Theme.barHeight; }
    Component.onCompleted: { updateZone(); reportWidth(); }
    Connections { target: Theme; function onBarHeightChanged() { bar.updateZone(); } }
    mask: cornersBelow ? bodyRegion : null
    Region { id: bodyRegion; item: body }

    // The bar itself (everything except outer corners)
    Item {
        id: body
        x: bar.cornersBeside ? bar.r : 0
        y: bar.cornersBelow && bar.atBottom ? bar.r : 0
        width: parent.width - (bar.cornersBeside ? 2 * bar.r : 0)
        height: Theme.barHeight
        clip: true

        // Solid style background. Touching the edge, it reaches past it, so that side looks square.
        Rectangle {
            visible: bar.solid
            readonly property int overhang: bar.attached ? radius + border.width : 0
            x: bar.attached && bar.full ? -overhang : 0
            width: parent.width + (bar.attached && bar.full ? 2 * overhang : 0)
            y: bar.atBottom ? 0 : -overhang
            height: parent.height + overhang
            radius: bar.full && bar.attached ? 0 : bar.r
            // A popout hanging flush from this end of the bar: square that corner so they join
            readonly property bool joinLeft: Globals.barJoin === bar.screen.name + ":left"
            readonly property bool joinRight: Globals.barJoin === bar.screen.name + ":right"
            bottomLeftRadius: !bar.atBottom && joinLeft ? 0 : radius
            bottomRightRadius: !bar.atBottom && joinRight ? 0 : radius
            topLeftRadius: bar.atBottom && joinLeft ? 0 : radius
            topRightRadius: bar.atBottom && joinRight ? 0 : radius
            color: BarConfig.solidColor
            border.width: BarConfig.borderWidth
            border.color: BarConfig.borderColor
            Behavior on color { ColorAnimation { duration: Theme.animMs } }
        }

        BarLane {
            id: left
            name: "left"
            barWindow: bar
            anchors.left: parent.left
            anchors.leftMargin: bar.solid ? 12 : Theme.barSideMargin
            anchors.verticalCenter: parent.verticalCenter
        }

        BarLane {
            id: center
            name: "center"
            barWindow: bar
            anchors.centerIn: parent
        }

        BarLane {
            id: right
            name: "right"
            barWindow: bar
            anchors.right: parent.right
            anchors.rightMargin: bar.solid ? 12 : Theme.barSideMargin
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Outer corners (fit width): left and right of the bar, against the screen edge
    OuterCorner {
        visible: bar.cornersBeside
        width: bar.r; height: bar.r
        x: 0
        y: bar.atBottom ? parent.height - bar.r : 0
        flipX: true; flipY: bar.atBottom
        color: BarConfig.solidColor
    }
    OuterCorner {
        visible: bar.cornersBeside
        width: bar.r; height: bar.r
        x: parent.width - bar.r
        y: bar.atBottom ? parent.height - bar.r : 0
        flipY: bar.atBottom
        color: BarConfig.solidColor
    }
    // Outer corners (full width): under the two ends of the bar
    OuterCorner {
        visible: bar.cornersBelow
        width: bar.r; height: bar.r
        x: 0
        y: bar.atBottom ? 0 : Theme.barHeight
        flipY: bar.atBottom
        color: BarConfig.solidColor
    }
    OuterCorner {
        visible: bar.cornersBelow
        width: bar.r; height: bar.r
        x: parent.width - bar.r
        y: bar.atBottom ? 0 : Theme.barHeight
        flipX: true; flipY: bar.atBottom
        color: BarConfig.solidColor
    }
}

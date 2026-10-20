import QtQuick
import QtQuick.Layouts
import qs

// Rounded "pill" background used by every bar module (like #clock, #tray… in Waybar).
// Its colors, border, roundness and padding come from Settings → Bar → Look,
// and from the widget's own ⚙ options (text/icon color, background).
Rectangle {
    id: pill

    readonly property bool isPill: true
    default property alias content: row.data
    property alias spacing: row.spacing
    // flat = no background of its own (inside a shared pill, or the Sleek bar)
    property bool flat: false
    // false = hidden (e.g. weather before it loads, media with nothing playing)
    property bool shown: true
    // This widget's options from Settings → Bar (e.g. { type: "clock", format: "hour" })
    property var settings: ({})
    visible: shown
    // Widget bubbles (Settings → Bar → Look): a tonal capsule behind the widget
    property bool bubble: true
    property bool inGroup: false          // sharing a bubble with its neighbours (set by the lane)            // false for widgets with their own shape (power, chip, tray…)
    readonly property bool showBubble: flat && bubble && BarConfig.bubbles && ownBackground === ""
    property int padding: flat ? (showBubble ? Math.max(10, BarConfig.flatPadding) : BarConfig.flatPadding) : BarConfig.pillPadding
    property bool interactive: true
    readonly property alias hovered: mouse.containsMouse

    // Used by BarText inside this pill
    readonly property color textColor: BarConfig.isCustom ? BarConfig.color(settings?.textColor, BarConfig.textColor) : BarConfig.textColor
    readonly property color iconColor: BarConfig.isCustom ? BarConfig.color(settings?.iconColor, BarConfig.iconColor) : BarConfig.iconColor
    readonly property string ownBackground: BarConfig.isCustom ? (settings?.background ?? "") : ""

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitHeight: Theme.barHeight
    scale: mouse.pressed && interactive ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2 * BarConfig.roundness
    color: ownBackground !== ""
        ? BarConfig.withOpacity(BarConfig.color(ownBackground, Theme.bg1), BarConfig.bgOpacity)
        : flat ? "transparent" : BarConfig.pillColor
    border.width: flat && ownBackground === "" ? 0 : BarConfig.borderWidth
    border.color: BarConfig.borderColor

    Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.animMs } }

    Rectangle {
        visible: pill.showBubble
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(parent.height - 6, 34)
        radius: height / 2
        color: BarConfig.bubbleColor
    }

    // Material state layer: a soft highlight on hover, stronger while pressed.
    // Own pill: fills it. Flat (shared pill / one-piece bar): a capsule centered on the content,
    // with even padding and the same height for every widget (it may spill into the gap beside it).
    property bool stateLayer: true
    property bool active: false            // e.g. keep awake on: its icon stays filled
    readonly property alias pressed: mouse.pressed
    Rectangle {
        readonly property int h: Math.min(pill.height - 6, 32)
        anchors.centerIn: row
        width: pill.showBubble ? pill.width : pill.flat ? Math.max(h, row.implicitWidth + 16) : pill.width
        height: pill.showBubble ? Math.min(pill.height - 6, 34) : pill.flat ? h : pill.height
        radius: pill.flat ? h / 2 : pill.radius
        color: pill.textColor
        opacity: !pill.interactive || !pill.stateLayer ? 0 : mouse.pressed ? 0.16 : mouse.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // Declared before the row so child items with their own MouseArea (tray) win
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: pill.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => pill.clicked(m)
        onWheel: w => pill.scrolled(w)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}

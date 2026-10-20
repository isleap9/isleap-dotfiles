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
    property int padding: flat ? BarConfig.flatPadding : BarConfig.pillPadding
    property bool interactive: true
    readonly property alias hovered: mouse.containsMouse

    // Used by BarText inside this pill
    readonly property color textColor: BarConfig.isCustom ? BarConfig.color(settings?.textColor, BarConfig.textColor) : BarConfig.textColor
    readonly property color iconColor: BarConfig.isCustom ? BarConfig.color(settings?.iconColor, BarConfig.iconColor) : BarConfig.iconColor
    readonly property string ownBackground: BarConfig.isCustom ? (settings?.background ?? "") : ""

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitHeight: Theme.barHeight
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2 * BarConfig.roundness
    color: ownBackground !== ""
        ? BarConfig.withOpacity(BarConfig.color(ownBackground, Theme.bg1), BarConfig.bgOpacity)
        : flat ? "transparent" : BarConfig.pillColor
    border.width: flat && ownBackground === "" ? 0 : BarConfig.borderWidth
    border.color: BarConfig.borderColor

    Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.animMs } }

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

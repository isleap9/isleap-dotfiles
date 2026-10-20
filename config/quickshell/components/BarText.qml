import QtQuick
import qs

// Bold text matching the Waybar modules (font-weight: 900).
// Color, size and weight follow Settings → Bar → Look and the widget's own ⚙ colors.
Text {
    property bool icon: false
    // The Pill this text sits in
    readonly property Item pill: {
        let p = parent;
        while (p && p.isPill !== true) p = p.parent;
        return p;
    }

    // Fluid fill: outlined at rest, fills in while hovered or when the widget is active (e.g. keep awake on)
    property real fill: icon && pill && ((pill.interactive && pill.hovered) || pill.active === true) ? 1 : 0
    Behavior on fill { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    color: pill ? (icon ? pill.iconColor : pill.textColor) : BarConfig.textColor
    font.family: icon ? Theme.iconFont : Theme.font
    font.variableAxes: icon ? Theme.iconAxesWith(fill) : ({})
    font.pixelSize: icon ? BarConfig.iconSize : BarConfig.textSize
    font.weight: icon ? Font.Normal : BarConfig.textWeight
    verticalAlignment: Text.AlignVCenter

    Behavior on color { ColorAnimation { duration: Theme.animMs } }
}

import QtQuick
import qs
import qs.components

// Empty space between widgets
Pill {
    interactive: false
    color: "transparent"
    padding: 0
    implicitWidth: BarConfig.opt(settings, "width") ?? 24
}

import QtQuick
import QtQuick.Layouts
import qs

// One lane of the bar (left, center or right): its widgets in order,
// either each in its own pill or all together in one shared pill.
Rectangle {
    id: lane

    required property string name
    required property var barWindow

    readonly property var widgets: BarConfig.lanes?.[name] ?? []
    readonly property bool grouped: (BarConfig.grouped?.[name] ?? false) && !BarConfig.solid
    readonly property int padding: grouped ? BarConfig.sharedPadding : 0

    visible: widgets.length > 0
    implicitHeight: Theme.barHeight
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2 * BarConfig.roundness
    color: grouped ? BarConfig.pillColor : "transparent"
    border.width: grouped ? BarConfig.borderWidth : 0
    border.color: BarConfig.borderColor

    Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.animMs } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: BarConfig.solid ? BarConfig.solidSpacing : Theme.spacing

        Repeater {
            model: lane.widgets

            BarWidget {
                required property var modelData
                widget: modelData
                barWindow: lane.barWindow
                // No pill of its own inside a shared pill or on the solid bar
                flat: lane.grouped || BarConfig.solid
            }
        }
    }
}

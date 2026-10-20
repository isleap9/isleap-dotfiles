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

        // Widgets marked "share a bubble with the next widget" are drawn together in one bubble
        Repeater {
            model: {
                const groups = [];
                let cur = [];
                for (const w of lane.widgets) {
                    cur.push(w);
                    if (!(BarConfig.isCustom && w.joinNext === true)) { groups.push(cur); cur = []; }
                }
                if (cur.length) groups.push(cur);
                return groups;
            }

            Item {
                id: group
                required property var modelData
                readonly property bool joined: modelData.length > 1
                readonly property bool bubble: joined && BarConfig.bubbles && (lane.grouped || BarConfig.solid)
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: inner.implicitWidth + (bubble ? 8 : 0)
                implicitHeight: Theme.barHeight
                visible: inner.visibleChildren.length > 0

                Rectangle {
                    visible: group.bubble
                    anchors.centerIn: parent
                    width: parent.width
                    height: Math.min(parent.height - 6, 34)
                    radius: height / 2
                    color: BarConfig.bubbleColor
                }

                RowLayout {
                    id: inner
                    anchors.centerIn: parent
                    spacing: group.joined ? 2 : 0

                    Repeater {
                        model: group.modelData

                        BarWidget {
                            required property var modelData
                            widget: modelData
                            barWindow: lane.barWindow
                            // No pill of its own inside a shared pill or on the solid bar
                            flat: lane.grouped || BarConfig.solid
                            inGroup: group.joined
                        }
                    }
                }
            }
        }
    }
}

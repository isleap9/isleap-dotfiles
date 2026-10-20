import QtQuick
import QtQuick.Layouts
import qs

// Editor for one lane of the Custom bar (left / center / right): reorder, move between lanes,
// per-widget options (⚙), remove, add. Changes apply to the bar immediately.
Rectangle {
    id: root

    required property string lane          // "left", "center", "right"
    required property string title
    readonly property var widgets: Config.bar.lanes?.[lane] ?? []
    readonly property int laneIndex: BarConfig.laneNames.indexOf(lane)
    property int openOptions: -1           // index of the widget whose options are shown
    property bool adding: false

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 24
    radius: 16
    color: Theme.bg2

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 6

        // Header: lane name + shared pill switch
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            spacing: 10

            Text {
                text: root.title
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Black
            }
            Text {
                Layout.fillWidth: true
                text: root.widgets.length === 0 ? "empty" : `${root.widgets.length} widget${root.widgets.length === 1 ? "" : "s"}`
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
            Text {
                visible: !BarConfig.customSolid
                text: "Shared pill"
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
            Toggle {
                visible: !BarConfig.customSolid
                scale: 0.85
                checked: Config.bar.grouped?.[root.lane] ?? false
                onToggled: BarConfig.setGrouped(root.lane, !checked)
            }
        }

        // Widgets in this lane
        Repeater {
            model: root.widgets

            ColumnLayout {
                id: entry
                required property var modelData
                required property int index
                readonly property var info: BarConfig.catalog[modelData.type] ?? { name: modelData.type, icon: "?", desc: "", options: [] }
                readonly property bool optionsOpen: root.openOptions === index
                // The widget's own options plus its colors
                readonly property var options: BarConfig.optionsFor(modelData.type)

                Layout.fillWidth: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 12
                    color: entry.optionsOpen ? Theme.bg3 : rowHover.hovered ? Theme.bg1 : "transparent"

                    HoverHandler { id: rowHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 10

                        Text {
                            Layout.preferredWidth: 22
                            horizontalAlignment: Text.AlignHCenter
                            text: entry.info.icon
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fontSize + 3
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: entry.info.name
                                color: Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: entry.info.desc
                                color: Theme.fg2
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 4
                                elide: Text.ElideRight
                            }
                        }

                        IconButton { icon: "󰁝"; enabled: entry.index > 0; onClicked: BarConfig.move(root.lane, entry.index, -1) }
                        IconButton { icon: "󰁅"; enabled: entry.index < root.widgets.length - 1; onClicked: BarConfig.move(root.lane, entry.index, 1) }
                        IconButton {
                            icon: "󰁍"   // to the lane on the left
                            enabled: root.laneIndex > 0
                            onClicked: BarConfig.moveToLane(root.lane, entry.index, BarConfig.laneNames[root.laneIndex - 1])
                        }
                        IconButton {
                            icon: "󰁔"   // to the lane on the right
                            enabled: root.laneIndex < 2
                            onClicked: BarConfig.moveToLane(root.lane, entry.index, BarConfig.laneNames[root.laneIndex + 1])
                        }
                        IconButton {
                            icon: "\u{F0493}"
                            visible: entry.options.length > 0
                            active: entry.optionsOpen
                            onClicked: root.openOptions = entry.optionsOpen ? -1 : entry.index
                        }
                        IconButton {
                            icon: "󰅖"
                            danger: true
                            onClicked: {
                                root.openOptions = -1;
                                BarConfig.remove(root.lane, entry.index);
                            }
                        }
                    }
                }

                // This widget's options
                ColumnLayout {
                    visible: entry.optionsOpen
                    Layout.fillWidth: true
                    Layout.leftMargin: 42
                    Layout.topMargin: 4
                    Layout.bottomMargin: 8
                    spacing: 6

                    Repeater {
                        model: entry.optionsOpen ? entry.options : []

                        RowLayout {
                            id: optRow
                            required property var modelData
                            readonly property var value: BarConfig.opt(entry.modelData, modelData.key)
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                text: optRow.modelData.label
                                color: Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                            }
                            Toggle {
                                visible: optRow.modelData.type === "toggle"
                                checked: optRow.value === true
                                onToggled: BarConfig.setOption(root.lane, entry.index, optRow.modelData.key, !checked)
                            }
                            Segmented {
                                visible: optRow.modelData.type === "choice"
                                options: optRow.modelData.choices ?? []
                                current: optRow.value
                                onSelected: v => BarConfig.setOption(root.lane, entry.index, optRow.modelData.key, v)
                            }
                            ColorChoice {
                                visible: optRow.modelData.type === "color"
                                value: optRow.value ?? ""
                                autoLabel: "Same as the bar"
                                onSelected: v => BarConfig.setOption(root.lane, entry.index, optRow.modelData.key, v)
                            }
                            Stepper {
                                visible: optRow.modelData.type === "number"
                                value: optRow.value ?? 0
                                from: optRow.modelData.from ?? 0
                                to: optRow.modelData.to ?? 100
                                step: optRow.modelData.step ?? 1
                                suffix: optRow.modelData.suffix ?? ""
                                onChanged: v => BarConfig.setOption(root.lane, entry.index, optRow.modelData.key, v)
                            }
                        }
                    }
                }
            }
        }

        // Add a widget
        PillButton {
            Layout.topMargin: 2
            icon: root.adding ? "󰅖" : "󰐕"
            text: root.adding ? "Cancel" : "Add widget"
            onClicked: root.adding = !root.adding
        }

        Flow {
            visible: root.adding
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.adding ? BarConfig.catalogOrder : []

                Rectangle {
                    id: chip
                    required property string modelData
                    readonly property var info: BarConfig.catalog[modelData]
                    implicitWidth: chipRow.implicitWidth + 24
                    implicitHeight: 32
                    radius: 16
                    color: chipArea.containsMouse ? Theme.accent : Theme.bg1

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: chip.info.icon
                            color: chipArea.containsMouse ? Theme.bg1 : Theme.fg1
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fontSize
                        }
                        Text {
                            text: chip.info.name
                            color: chipArea.containsMouse ? Theme.bg1 : Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Font.Bold
                        }
                    }
                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            BarConfig.add(root.lane, chip.modelData);
                            root.adding = false;
                        }
                    }
                }
            }
        }
    }
}

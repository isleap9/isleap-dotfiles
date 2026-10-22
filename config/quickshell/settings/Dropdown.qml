import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs
import qs.components

// Material 3 dropdown (exposed dropdown menu).
// options: [{ value, label, description?, preview?, font?, hidden? }]
//   preview — an icon font: the option shows a few sample icons in it
//   font    — draw the label in this font (font pickers)
//   hidden  — only listed when it matches a search
// searchable: adds a search field (type to filter; ↑ ↓ Enter to pick). Long lists scroll.
// The menu is drawn on top of the whole window, so scrolling pages never clip it.
Rectangle {
    id: root

    property var options: []
    property var current
    property bool searchable: false
    property string placeholder: "Search"
    property int maxMenuHeight: 420
    signal selected(var value)

    readonly property var currentOption: options.find(o => o.value === current) ?? null
    property bool open: false
    property string query: ""

    readonly property var shown: {
        const q = query.trim().toLowerCase();
        if (!q) return options.filter(o => !o.hidden || o.value === current);
        return options.filter(o => o.label.toLowerCase().includes(q) || (o.description ?? "").toLowerCase().includes(q));
    }

    function pick(o) {
        open = false;
        if (o && o.value !== current) selected(o.value);
    }

    onOpenChanged: {
        if (!open) return;
        query = "";
        search.text = "";
        list.currentIndex = Math.max(0, shown.findIndex(o => o.value === current));
        list.positionViewAtIndex(list.currentIndex, ListView.Center);
        if (searchable) search.forceActiveFocus();
        else list.forceActiveFocus();
    }

    implicitWidth: 240
    implicitHeight: 40
    radius: open ? 12 : 20
    Behavior on radius { NumberAnimation { duration: 150 } }
    color: Theme.bg2
    border.width: open ? 2 : 0
    border.color: Theme.accent

    // State layer
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.fg1
        opacity: fieldArea.pressed ? 0.12 : fieldArea.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 10
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: root.currentOption?.label ?? (root.current ? String(root.current) : "Choose…")
            color: Theme.fg1
            font.family: root.currentOption?.font ?? Theme.font
            font.pixelSize: Theme.fontSize - 1
            elide: Text.ElideRight
        }
        Text {
            text: "arrow_drop_down"
            color: root.open ? Theme.accent : Theme.fg2
            font.family: Theme.iconFont
            font.variableAxes: Theme.iconAxes
            font.pixelSize: Theme.fontSize + 6
            rotation: root.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
        }
    }

    MouseArea {
        id: fieldArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }

    // ---- the menu, reparented to the window so nothing clips it ----
    Item {
        id: overlay
        parent: root.Window.contentItem
        anchors.fill: parent
        z: 1000
        visible: root.open || menu.opacity > 0

        // Click outside closes
        MouseArea {
            anchors.fill: parent
            enabled: root.open
            acceptedButtons: Qt.AllButtons
            onPressed: root.open = false
            onWheel: root.open = false
        }

        Rectangle {
            id: menu
            readonly property point at: root.open || opacity > 0 ? root.mapToItem(overlay, 0, 0) : Qt.point(0, 0)
            readonly property real spaceBelow: overlay.height - (at.y + root.height + 6) - 8
            readonly property real spaceAbove: at.y - 6 - 8
            readonly property real natural: (root.searchable ? searchBox.height + 6 : 0) + Math.max(list.contentHeight, 44) + 12
            // Below the field, unless it doesn't fit and there's more room above
            readonly property bool above: natural > spaceBelow && spaceAbove > spaceBelow
            x: Math.max(8, Math.min(at.x, overlay.width - width - 8))
            y: above ? at.y - height - 6 : at.y + root.height + 6
            width: Math.max(root.width, 320)
            height: Math.min(natural, root.maxMenuHeight, above ? spaceAbove : spaceBelow)
            radius: 16
            color: Theme.bg1
            border.width: 1
            border.color: Qt.rgba(Theme.fg1.r, Theme.fg1.g, Theme.fg1.b, 0.06)

            transformOrigin: above ? Item.Bottom : Item.Top
            scale: root.open ? 1 : 0.92
            opacity: root.open ? 1 : 0
            Behavior on scale { NumberAnimation { duration: Theme.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
            Behavior on opacity { NumberAnimation { duration: root.open ? Theme.animMs * 0.6 : Theme.animMs * 0.4 } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 0.8
                shadowVerticalOffset: 6
            }

            MouseArea { anchors.fill: parent }

            // Search field
            Rectangle {
                id: searchBox
                visible: root.searchable
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                height: root.searchable ? 40 : 0
                radius: 20
                color: Theme.bg0
                border.width: search.activeFocus ? 2 : 0
                border.color: Theme.accent
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    Text {
                        text: "search"
                        color: search.activeFocus ? Theme.accent : Theme.fg2
                        font.family: Theme.iconFont
                        font.variableAxes: Theme.iconAxes
                        font.pixelSize: Theme.fontSize + 3
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        clip: true
                        color: Theme.fg1
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.bg0
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        onTextChanged: { root.query = text; list.currentIndex = 0; list.positionViewAtBeginning(); }
                        Keys.onEscapePressed: root.open = false
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onReturnPressed: root.pick(root.shown[list.currentIndex])
                        Keys.onEnterPressed: root.pick(root.shown[list.currentIndex])
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: root.placeholder
                            color: Theme.fg2
                            font: search.font
                        }
                    }
                    Text {
                        text: root.shown.length
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 4
                    }
                }
            }

            ListView {
                id: list
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: root.searchable ? searchBox.bottom : parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 6
                clip: true
                spacing: 2
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                keyNavigationEnabled: true
                Keys.onEscapePressed: root.open = false
                Keys.onReturnPressed: root.pick(root.shown[currentIndex])
                SmoothWheel { flick: list }
                MScrollBar { flick: list }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool chosen: modelData.value === root.current
                    readonly property bool keyed: ListView.isCurrentItem && (search.activeFocus || list.activeFocus)

                    width: list.width - (list.contentHeight > list.height ? 12 : 0)
                    height: Math.max(44, rowContent.implicitHeight + 16)
                    radius: 12
                    color: chosen ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : "transparent"

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.fg1
                        opacity: rowArea.pressed ? 0.12 : rowArea.containsMouse || row.keyed ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    RowLayout {
                        id: rowContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            Layout.preferredWidth: 20
                            text: "check"
                            opacity: row.chosen ? 1 : 0
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: Theme.fontSize + 2
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.label
                                color: row.chosen ? Theme.accent : Theme.fg1
                                font.family: row.modelData.font ?? Theme.font
                                font.pixelSize: Theme.fontSize - (row.modelData.font ? 0 : 1)
                                font.weight: row.chosen ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.description ?? ""
                                color: Theme.fg2
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 4
                                elide: Text.ElideRight
                            }
                        }
                        // Sample icons drawn in this option's icon font
                        Row {
                            visible: !!row.modelData.preview
                            spacing: 4
                            Repeater {
                                model: row.modelData.preview ? ["home", "settings", "favorite"] : []
                                Text {
                                    required property string modelData
                                    text: modelData
                                    color: row.chosen ? Theme.accent : Theme.fg2
                                    font.family: row.modelData.preview ?? Theme.iconFont
                                    font.variableAxes: Theme.iconAxes
                                    font.pixelSize: Theme.fontSize + 2
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pick(row.modelData)
                    }
                }

                // Nothing matches the search
                Text {
                    parent: list
                    anchors.centerIn: parent
                    visible: root.shown.length === 0
                    text: "No matches"
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }
    }
}

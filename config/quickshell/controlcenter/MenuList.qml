import QtQuick
import QtQuick.Layouts
import qs
import qs.components

// Searchable, keyboard-driven list used by most control center pages.
// items: [{ icon, label, sub, swatches: [colors], checked, image, actions: [{ icon, id, tip }] }]
ColumnLayout {
    id: root

    property var items: []
    property string placeholder: "Search…"
    property bool searchable: true
    property string emptyText: "Nothing here"
    property alias query: search.text
    property alias currentIndex: list.currentIndex
    property int rowHeight: 52

    signal activated(var item)
    signal action(var item, string id)
    signal back()

    readonly property var filtered: {
        const q = search.text.trim().toLowerCase();
        if (q === "") return items;
        return items.filter(i => (i.label + " " + (i.sub ?? "") + " " + (i.keywords ?? ""))
            .toLowerCase().includes(q));
    }

    function focusSearch() { search.forceActiveFocus(); }

    spacing: 10

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44
        radius: 22
        color: Theme.bg1
        visible: root.searchable

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 10

            Text {
                text: "search"
                color: Theme.fg2
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxes
                font.pixelSize: Theme.fontSize + 2
            }

            TextInput {
                id: search
                Layout.fillWidth: true
                focus: true
                color: Theme.fg1
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Bold
                onTextChanged: list.currentIndex = 0

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: root.placeholder
                    color: Theme.fg2
                    font: search.font
                }

                Keys.onEscapePressed: search.text !== "" ? search.text = "" : root.back()
                Keys.onReturnPressed: root.activateCurrent()
                Keys.onEnterPressed: root.activateCurrent()
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onDownPressed: list.incrementCurrentIndex()
                Keys.onTabPressed: list.incrementCurrentIndex()
                Keys.onBacktabPressed: list.decrementCurrentIndex()
                Keys.onPressed: e => {
                    // Backspace on an empty search goes back a page
                    if (e.key === Qt.Key_Backspace && search.text === "") { root.back(); e.accepted = true; }
                }
            }
        }
    }

    function activateCurrent() {
        const item = filtered[list.currentIndex];
        if (item) activated(item);
    }

    ListView {
        SmoothWheel { flick: list }
        MScrollBar { flick: list }
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: root.filtered
        highlightMoveDuration: 120
        keyNavigationWraps: true
        boundsBehavior: Flickable.StopAtBounds

        highlight: Rectangle { radius: 16; color: Theme.bg3 }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: root.emptyText
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: ListView.view.width
            height: modelData.image ? 96 : root.rowHeight

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: root.activated(row.modelData)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 12

                Text {
                    visible: !!row.modelData.icon
                    Layout.preferredWidth: 26
                    horizontalAlignment: Text.AlignHCenter
                    text: row.modelData.icon ?? ""
                    color: row.modelData.checked ? Theme.accent : Theme.fg1
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: Theme.fontSize + 5
                }

                Image {
                    visible: !!row.modelData.image
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 80
                    source: row.modelData.image ?? ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    sourceSize.width: 280
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.label
                        color: Theme.fg1
                        font.family: row.modelData.mono ? Theme.iconFont : Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        textFormat: Text.PlainText
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !!row.modelData.sub
                        text: row.modelData.sub ?? ""
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }

                // Color swatches (themes)
                Row {
                    visible: (row.modelData.swatches ?? []).length > 0
                    spacing: -6
                    Repeater {
                        model: row.modelData.swatches ?? []
                        Rectangle {
                            required property string modelData
                            width: 22; height: 22; radius: 11
                            color: modelData
                            border.color: Theme.bg0
                            border.width: 2
                        }
                    }
                }

                Text {
                    visible: row.modelData.checked === true
                    text: "check"
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: Theme.fontSize + 4
                }

                // Per-row buttons (clipboard star/delete)
                Repeater {
                    model: row.modelData.actions ?? []
                    Rectangle {
                        id: btn
                        required property var modelData
                        implicitWidth: 34; implicitHeight: 34; radius: 17
                        color: btnArea.containsMouse ? Theme.bg2 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: btn.modelData.icon
                            color: btn.modelData.active ? Theme.accent : Theme.fg2
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: Theme.fontSize + 2
                        }
                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.action(row.modelData, btn.modelData.id)
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs

// Pick a color from the current theme (so it follows the theme switcher), or type a #hex.
// value: "" (automatic), a theme color name ("accent", "fg1", "red"…) or "#rrggbb".
ColumnLayout {
    id: root

    property string value: ""
    property string autoLabel: "Auto"
    signal selected(string value)

    readonly property var names: ["", "accent", "fg1", "fg2", "surface", "bg0", "bg1", "bg2",
        "bg3", "bg4", "red", "orange", "yellow", "green", "cyan", "blue", "purple"]
    readonly property bool isHex: value.startsWith("#")
    readonly property var labels: ({
        accent: "Accent", fg1: "Text", fg2: "Dim text", surface: "Surface", bg0: "Background 0 (darkest)",
        bg1: "Background 1", bg2: "Background 2", bg3: "Background 3", bg4: "Background 4", red: "Red",
        orange: "Orange", yellow: "Yellow", green: "Green", cyan: "Cyan", blue: "Blue", purple: "Purple"
    })
    property string hovered: ""

    spacing: 6

    Grid {
        columns: 9
        spacing: 5

        Repeater {
            model: root.names

            Rectangle {
                id: swatch
                required property string modelData
                readonly property bool active: root.value === modelData
                width: 24; height: 24; radius: 12
                color: modelData === "" ? Theme.bg2 : Theme[modelData]
                border.width: active ? 3 : 1
                border.color: active ? Theme.fg1 : area.containsMouse ? Theme.fg2 : Theme.bg4

                // "Auto": a slash through an empty swatch
                Rectangle {
                    visible: swatch.modelData === ""
                    anchors.centerIn: parent
                    width: 2; height: 16
                    rotation: 45
                    color: Theme.fg2
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(swatch.modelData)
                    onContainsMouseChanged: root.hovered = containsMouse ? (swatch.modelData === "" ? "-auto-" : swatch.modelData) : ""
                }
            }
        }
    }

    RowLayout {
        spacing: 8
        Text {
            readonly property string shown: root.hovered !== "" ? root.hovered : root.value
            text: shown === "" || shown === "-auto-" ? root.autoLabel : shown.startsWith("#") ? "Custom" : (root.labels[shown] ?? shown)
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
        }
        TextBox {
            implicitWidth: 120
            implicitHeight: 28
            text: root.isHex ? root.value : ""
            placeholder: "#hex"
            valid: text === "" || /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(text)
            onAccepted: v => {
                const t = v.trim();
                if (t === "") return;
                const hex = t.startsWith("#") ? t : "#" + t;
                if (/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(hex)) root.selected(hex);
            }
        }
    }
}

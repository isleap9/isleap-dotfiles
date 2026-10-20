import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

// Emoji picker (data from rofimoji). Type to search, ↑/↓/Tab to move, Enter or click to copy.
ColumnLayout {
    id: root

    property var cc   // set by the loader

    property var all: []   // [{ e, name, kw, cat }]
    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        if (q === "") return all;
        const words = q.split(/\s+/);
        return all.filter(x => words.every(w => x.name.includes(w) || x.kw.includes(w) || x.cat.includes(w)));
    }
    readonly property int columns: Math.max(1, Math.floor(grid.width / grid.cellWidth))
    readonly property var current: shown[grid.currentIndex] ?? null

    function focusSearch() { search.forceActiveFocus(); }

    function copy(item) {
        if (!item) return;
        Quickshell.execDetached(["wl-copy", item.e]);
        Globals.controlCenterOpen = false;
    }

    spacing: 10

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44
        radius: 22
        color: Theme.bg1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 10

            Text {
                text: "󰍉"
                color: Theme.fg2
                font.family: Theme.iconFont
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
                onTextChanged: grid.currentIndex = 0

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "Search emoji…"
                    color: Theme.fg2
                    font: search.font
                }

                Keys.onEscapePressed: search.text !== "" ? search.text = "" : root.cc?.go("main")
                Keys.onReturnPressed: root.copy(root.current)
                Keys.onEnterPressed: root.copy(root.current)
                Keys.onUpPressed: grid.moveCurrentIndexUp()
                Keys.onDownPressed: grid.moveCurrentIndexDown()
                Keys.onTabPressed: grid.moveCurrentIndexRight()
                Keys.onBacktabPressed: grid.moveCurrentIndexLeft()
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Backspace && search.text === "") { root.cc?.go("main"); e.accepted = true; }
                }
            }
        }
    }

    GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        cellWidth: 52
        cellHeight: 52
        model: root.shown
        highlightMoveDuration: 80
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationWraps: true

        highlight: Rectangle { radius: 14; color: Theme.bg3 }

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight

            Text {
                anchors.centerIn: parent
                text: cell.modelData.e
                font.pixelSize: 28
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: grid.currentIndex = cell.index
                onClicked: root.copy(cell.modelData)
            }
        }

        Text {
            anchors.centerIn: parent
            visible: grid.count === 0
            text: root.all.length === 0 ? "Loading emoji…" : "No emoji found"
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    // Name of the highlighted emoji
    Text {
        Layout.fillWidth: true
        text: root.current ? `${root.current.e}  ${root.current.name}` : " "
        color: Theme.fg2
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        elide: Text.ElideRight
    }

    Process {
        running: true
        command: ["sh", "-c", `
            d=$(ls -d /usr/lib/python3*/site-packages/picker/data 2>/dev/null | head -1)
            for f in "$d"/emojis_*.csv; do
                case "$f" in *component*) continue ;; esac
                c=$(basename "$f" .csv); c=\${c#emojis_}
                sed "s/^/$c\t/" "$f"
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    // "<category>\t<emoji> <name> <small>(<keywords>)</small>"
                    const m = line.match(/^([^\t]+)\t(\S+) (.*?)(?: <small>\((.*)\)<\/small>)?$/);
                    if (m) out.push({ cat: m[1].replace(/_/g, " "), e: m[2], name: m[3].toLowerCase(), kw: (m[4] ?? "").toLowerCase() });
                }
                root.all = out;
            }
        }
    }
}

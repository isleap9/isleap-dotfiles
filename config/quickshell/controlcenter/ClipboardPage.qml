import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

// Clipboard history (cliphist) + favorites (~/.config/cliphist/favorites, same file as before)
ColumnLayout {
    id: root

    property var cc   // set by the loader

    readonly property string favFile: Quickshell.env("HOME") + "/.config/cliphist/favorites"
    readonly property string imgDir: Quickshell.env("XDG_RUNTIME_DIR") + "/qs-clipboard"
    property string tab: "history"
    property var history: []       // raw "id<TAB>preview" lines
    property var favorites: []
    property bool confirmWipe: false

    function focusSearch() { list.focusSearch(); }
    function refresh() { histProc.running = true; }

    // Run a shell snippet with $1 = the clipboard line/text
    function sh(script, arg) {
        Quickshell.execDetached(["sh", "-c", script, "sh", arg ?? ""]);
    }

    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: [["history", "content_paste", "History"], ["favorites", "star", "Favorites"]]
            Tab {
                required property var modelData
                icon: modelData[1]
                label: modelData[2]
                active: root.tab === modelData[0]
                onClicked: { root.tab = modelData[0]; list.query = ""; list.focusSearch(); }
            }
        }

        Item { Layout.fillWidth: true }

        Tab {
            visible: root.tab === "history"
            icon: "clear_all"
            label: root.confirmWipe ? "Click again to clear" : "Clear"
            danger: root.confirmWipe
            onClicked: {
                if (!root.confirmWipe) { root.confirmWipe = true; wipeTimer.restart(); return; }
                root.confirmWipe = false;
                root.sh("cliphist wipe");
                root.history = [];
            }
        }
    }

    MenuList {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        placeholder: root.tab === "history" ? "Search clipboard…" : "Search favorites…"
        emptyText: root.tab === "history" ? "Clipboard is empty" : "No favorites yet — star something in History"

        items: root.tab === "history"
            ? root.history.map(line => {
                const tabAt = line.indexOf("\t");
                const id = line.slice(0, tabAt);
                const preview = line.slice(tabAt + 1);
                const img = preview.match(/^\[\[ binary data (.*?) (\w+) (\d+x\d+) \]\]$/);
                return img
                    ? { label: `Image ${img[3]}`, sub: `${img[2].toUpperCase()} · ${img[1]}`, line, isImage: true,
                        image: `file://${root.imgDir}/${id}.${img[2]}`,
                        actions: [{ icon: "delete", id: "del" }] }
                    : { icon: "content_paste", label: preview.trim(), line,
                        actions: [{ icon: root.favorites.includes(preview) ? "star" : "star_border", id: "fav",
                                    active: root.favorites.includes(preview) },
                                  { icon: "delete", id: "del" }] };
            })
            : root.favorites.map((text, i) => ({
                icon: "star", label: text, index: i,
                actions: [{ icon: "delete", id: "unfav" }]
            }))

        onActivated: item => {
            if (root.tab === "history") root.sh(`printf '%s' "$1" | cliphist decode | wl-copy`, item.line);
            else root.sh(`printf '%s' "$1" | wl-copy`, item.label);
            Globals.controlCenterOpen = false;
        }

        onAction: (item, id) => {
            if (id === "del") {
                root.sh(`printf '%s' "$1" | cliphist delete`, item.line);
                root.history = root.history.filter(l => l !== item.line);
            } else if (id === "fav") {
                // Same behavior as the old script: store the decoded text, skip duplicates
                root.sh(`F="${root.favFile}"; mkdir -p "$(dirname "$F")"; touch "$F"
                         D=$(printf '%s' "$1" | cliphist decode)
                         grep -qxF -- "$D" "$F" || printf '%s\\n' "$D" >> "$F"`, item.line);
            } else if (id === "unfav") {
                root.sh(`sed -i "$1d" "${root.favFile}"`, String(item.index + 1));
            }
        }

        onBack: root.cc?.go("main")
    }

    Timer { id: wipeTimer; interval: 3000; onTriggered: root.confirmWipe = false }

    // History, plus decoded image previews for picture entries
    Process {
        id: histProc
        running: true
        command: ["sh", "-c", `
            mkdir -p "${root.imgDir}"
            cliphist list | head -200 > "${root.imgDir}/list"
            grep -P '^\\d+\\t\\[\\[ binary data' "${root.imgDir}/list" | head -40 | while IFS= read -r line; do
                id=\${line%%\t*}
                ext=$(printf '%s' "$line" | grep -oP '\\w+(?= \\d+x\\d+ \\]\\]$)')
                f="${root.imgDir}/$id.$ext"
                [ -s "$f" ] || printf '%s' "$line" | cliphist decode > "$f"
            done
            cat "${root.imgDir}/list"`]
        stdout: StdioCollector {
            onStreamFinished: root.history = text.split("\n").filter(l => l.includes("\t"))
        }
    }

    FileView {
        path: root.favFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.favorites = text().split("\n").filter(l => l.trim() !== "")
        onLoadFailed: root.favorites = []
    }

    component Tab: Rectangle {
        id: tabBtn
        property string icon
        property string label
        property bool active: false
        property bool danger: false
        signal clicked

        implicitHeight: 34
        implicitWidth: tabRow.implicitWidth + 28
        radius: 17
        color: danger ? Theme.red : active ? Theme.accent : tabArea.containsMouse ? Theme.bg3 : Theme.bg1

        RowLayout {
            id: tabRow
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: tabBtn.icon
                color: tabBtn.active || tabBtn.danger ? Theme.bg1 : Theme.fg1
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxes
                font.pixelSize: Theme.fontSize + 1
            }
            Text {
                text: tabBtn.label
                color: tabBtn.active || tabBtn.danger ? Theme.bg1 : Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Bold
            }
        }
        MouseArea {
            id: tabArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tabBtn.clicked()
        }
    }
}

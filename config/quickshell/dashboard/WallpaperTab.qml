import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.components

// Wallpapers: your ~/Pictures/Wallpapers as a grid. Click one to apply it (with the fade,
// and new colors if the Dynamic theme is on). Type to search by file name.
Item {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string current: ""
    property string query: ""
    property string applying: ""

    implicitWidth: 6 * 128 + 5 * 8
    implicitHeight: 560

    function apply(path) {
        applying = path;
        current = path;
        setter.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/set-wallpaper.sh", path];
        setter.running = true;
    }

    Process {
        running: true
        command: ["sh", "-c", "awww query 2>/dev/null | head -1 | sed 's/.*image: //'"]
        stdout: StdioCollector { onStreamFinished: root.current = text.trim() }
    }
    Process { id: setter; onExited: root.applying = "" }

    FolderListModel {
        id: files
        folder: "file://" + root.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp"]
        showDirs: false
        sortField: FolderListModel.Time
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Search
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 24
                color: Theme.bg1
                border.width: search.activeFocus ? 2 : 0
                border.color: Theme.accent
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12
                    Text {
                        text: "search"
                        color: Theme.fg2
                        font.family: Theme.iconFont
                        font.variableAxes: Theme.iconAxes
                        font.pixelSize: 20
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        onTextChanged: root.query = text.toLowerCase()
                        Text {
                            visible: search.text === ""
                            text: `Search ${files.count} wallpapers`
                            color: Theme.fg2
                            font: search.font
                        }
                    }
                }
            }
            DashButton {
                icon: "folder_open"
                size: 44
                onClicked: Qt.openUrlExternally("file://" + root.folder)
            }
        }

        GridView {
            SmoothWheel { flick: grid }
            MScrollBar { flick: grid }
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 4
            cellHeight: cellWidth * 0.62
            cacheBuffer: 600
            boundsBehavior: Flickable.StopAtBounds
            model: files

            delegate: Item {
                id: cell
                required property string fileName
                required property string filePath
                readonly property bool matches: root.query === "" || fileName.toLowerCase().includes(root.query)
                readonly property bool isCurrent: filePath === root.current
                width: matches ? grid.cellWidth : 0
                height: matches ? grid.cellHeight : 0
                visible: matches

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: cell.isCurrent ? 24 : area.containsMouse ? 20 : 16
                    color: Theme.bg2
                    border.width: cell.isCurrent ? 3 : 0
                    border.color: Theme.accent
                    Behavior on radius { NumberAnimation { duration: 150 } }

                    Image {
                        anchors.fill: parent
                        anchors.margins: cell.isCurrent ? 3 : 0
                        source: "file://" + cell.filePath
                        sourceSize.width: 320
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: area.containsMouse ? 0.15 : 0
                    }
                    // Current: check badge
                    Rectangle {
                        visible: cell.isCurrent
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        width: 28; height: 28; radius: 14
                        color: Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: root.applying === cell.filePath ? "refresh" : "check"
                            color: Theme.bg0
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: 17
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(cell.filePath)
                    }
                }
            }
        }
    }
}

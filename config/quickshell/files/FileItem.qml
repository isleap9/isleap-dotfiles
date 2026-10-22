import QtQuick
import QtQuick.Layouts
import qs

// One file or folder, as a grid tile or a list row. Selection / opening is handled by the explorer.
Item {
    id: item

    required property int index
    required property string fileName
    required property string filePath
    required property bool fileIsDir
    required property var fileSize
    required property var fileModified

    property var explorer
    property bool listMode: false
    property int iconSize: 72
    property bool showFolder: false    // search results: show the containing folder

    readonly property bool selected: explorer.selected[filePath] === true
    readonly property bool cut: explorer.clipCut && explorer.clipPaths.indexOf(filePath) >= 0
    readonly property bool hidden: fileName.startsWith(".")
    readonly property bool hovered: area.containsMouse
    // A drag is hovering over this folder
    readonly property bool dropTarget: drop.containsDrag && drop.valid

    // Card with M3 state layers
    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: item.listMode ? 1 : 4
        radius: item.listMode ? height / 2 : 20
        color: item.dropTarget ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
            : item.selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"
        border.width: item.dropTarget ? 2 : item.selected && !item.listMode ? 1 : 0
        border.color: item.dropTarget ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
        Behavior on color { ColorAnimation { duration: 150 } }
        opacity: item.cut || area.drag.active ? 0.45 : item.hidden ? 0.7 : 1
        Behavior on opacity { NumberAnimation { duration: 150 } }

        scale: item.dropTarget ? 1.05 : area.pressed && !area.drag.active ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 2 } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: item.selected ? Theme.accent : Theme.fg1
            opacity: area.pressed ? 0.12 : item.hovered ? 0.07 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        // Grid tile
        ColumnLayout {
            visible: !item.listMode
            anchors.fill: parent
            anchors.margins: 8
            anchors.topMargin: 12
            spacing: 8

            FileIcon {
                id: gridIcon
                Layout.alignment: Qt.AlignHCenter
                size: item.iconSize
                path: item.filePath
                name: item.fileName
                isDir: item.fileIsDir
                active: item.hovered || item.selected || item.dropTarget
                // Gentle lift on hover
                transform: Translate {
                    y: item.hovered ? -2 : 0
                    Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: item.fileName
                color: item.selected ? Theme.accent : Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                font.weight: item.selected ? Font.DemiBold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                elide: Text.ElideMiddle
            }
        }

        // List row
        RowLayout {
            visible: item.listMode
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 18
            spacing: 14

            FileIcon {
                size: 32
                path: item.filePath
                name: item.fileName
                isDir: item.fileIsDir
                active: item.hovered || item.selected || item.dropTarget
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: item.fileName
                    color: item.selected ? Theme.accent : Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: item.selected ? Font.DemiBold : Font.Normal
                    elide: Text.ElideMiddle
                }
                Text {
                    Layout.fillWidth: true
                    visible: item.showFolder
                    text: item.explorer.prettyPath(item.filePath.substring(0, item.filePath.lastIndexOf("/")) || "/")
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 4
                    elide: Text.ElideMiddle
                }
            }
            Text {
                Layout.preferredWidth: 170
                text: FileTypes.date(item.fileModified)
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
                elide: Text.ElideRight
            }
            Text {
                Layout.preferredWidth: 80
                horizontalAlignment: Text.AlignRight
                text: item.fileIsDir ? "—" : FileTypes.size(item.fileSize)
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: card
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        drag.target: dragHandle
        drag.threshold: 8
        onPressed: mouse => {
            item.explorer.focusView();
            if (mouse.button !== Qt.LeftButton) return;
            // Drag the selection if this item is part of it, otherwise just this item
            item.dragPaths = item.selected ? item.explorer.selectedPaths() : [item.filePath];
            item.explorer.prepareDragImage(item.filePath, item.fileName, item.fileIsDir, item.dragPaths.length);
        }
        drag.onActiveChanged: if (drag.active && !item.selected) item.explorer.selectOnly(item.filePath)
        onClicked: mouse => {
            const p = mapToItem(null, mouse.x, mouse.y);
            item.explorer.itemClicked(item.index, item.filePath, item.fileIsDir, mouse.button, mouse.modifiers, p.x, p.y);
        }
        onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) item.explorer.open(item.filePath, item.fileIsDir);
        }
    }

    // Drag out: a real system drag carrying file URIs, so it also works with other apps
    property var dragPaths: []
    Item {
        id: dragHandle
        Drag.active: area.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
        Drag.proposedAction: Qt.MoveAction
        Drag.mimeData: ({ "text/uri-list": item.dragPaths.map(p => FileTypes.url(p)).join("\r\n") })
        Drag.imageSource: item.explorer.dragImage
        Drag.hotSpot.x: 36
        Drag.hotSpot.y: 36
        Drag.onDragFinished: { dragHandle.x = 0; dragHandle.y = 0; }
    }

    // Drop onto a folder
    DropArea {
        id: drop
        anchors.fill: card
        enabled: item.fileIsDir
        keys: ["text/uri-list"]
        property bool valid: false
        onEntered: d => { valid = item.explorer.canDrop(d.urls, item.filePath); d.accepted = valid; }
        onExited: valid = false
        onDropped: d => { valid = false; item.explorer.handleDrop(d, item.filePath); }
    }
    // Hovering a drag over a folder for a moment opens it
    Timer {
        running: item.dropTarget
        interval: 900
        onTriggered: item.explorer.go(item.filePath)
    }
}

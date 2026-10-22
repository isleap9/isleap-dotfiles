import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.components

// A file's picture: a thumbnail for images and videos, otherwise a Material symbol on a tonal tile.
// Folders use the accent color; the symbol fills in on hover / selection (Material "fluid" icons).
Item {
    id: root

    property string path
    property string name
    property bool isDir
    property bool active            // hovered or selected
    property int size: 72

    readonly property string kind: FileTypes.kind(name, isDir)
    // Images load directly; videos and PDFs get a cached preview made on first sight
    readonly property bool generated: kind === "video" || kind === "pdf"
    readonly property bool thumbable: Config.files.thumbnails && (kind === "image" || generated)
    readonly property string thumbFile: generated
        ? Quickshell.env("HOME") + "/.cache/quickshell/thumbs/" + Qt.md5(path) + ".png" : ""
    property bool thumbFailed: false

    implicitWidth: size
    implicitHeight: size

    // Tonal tile with the symbol (also shown while a thumbnail loads)
    Rectangle {
        anchors.fill: parent
        visible: !thumb.visible
        radius: Math.round(root.size * 0.28)
        color: root.isDir ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, root.active ? 0.22 : 0.13)
            : root.active ? Theme.bg2 : Theme.bg1
        Behavior on color { ColorAnimation { duration: 150 } }

        CenteredIcon {
            text: FileTypes.icon(root.name, root.isDir)
            color: root.isDir ? Theme.accent : Theme.fg2
            size: Math.round(root.size * 0.5)
            fill: root.active || root.isDir ? 1 : 0
        }
    }

    ClippingRectangle {
        id: thumb
        anchors.fill: parent
        radius: Math.round(root.size * 0.2)
        color: Theme.bg1
        visible: root.thumbable && !root.thumbFailed && img.status === Image.Ready
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Image {
            id: img
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(256, 256)
            source: !root.thumbable || root.thumbFailed ? ""
                : root.kind === "image" ? FileTypes.url(root.path) : "file://" + root.thumbFile
            onStatusChanged: {
                if (status !== Image.Error) return;
                if (root.generated && !makeThumb.tried) makeThumb.running = true;
                else root.thumbFailed = true;
            }
        }
    }

    // Video frame (ffmpegthumbnailer) or PDF first page (pdftoppm), cached in ~/.cache/quickshell/thumbs
    Process {
        id: makeThumb
        property bool tried: false
        command: ["sh", "-c", root.kind === "pdf"
            ? 'mkdir -p "$(dirname "$2")" && pdftoppm -png -singlefile -f 1 -l 1 -scale-to 256 "$1" "${2%.png}"'
            : 'mkdir -p "$(dirname "$2")" && ffmpegthumbnailer -i "$1" -o "$2" -s 256 -q 6',
            "sh", root.path, root.thumbFile]
        onRunningChanged: if (running) tried = true
        onExited: code => {
            if (code !== 0) { root.thumbFailed = true; return; }
            img.source = "";
            img.source = "file://" + root.thumbFile;
        }
    }
}

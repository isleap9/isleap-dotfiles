import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs
import qs.components

// Now playing — a small version of the dashboard's media card: cover, title over artist,
// a thin progress line, and previous / play-pause / next.
// Click the cover or title: the dashboard's Media tab. Scroll: next/previous track.
// Options (Settings → Bar → Now playing ⚙): max width, cover, artist line, progress, buttons.
Pill {
    id: root

    property var screen: null
    readonly property MprisPlayer p: Players.active
    readonly property int maxTextWidth: BarConfig.opt(settings, "maxWidth") ?? 420
    readonly property bool showCover: BarConfig.opt(settings, "cover") !== false
    readonly property bool showArtist: BarConfig.opt(settings, "artist") !== false
    readonly property bool showProgress: BarConfig.opt(settings, "progress") !== false
    readonly property bool showControls: BarConfig.opt(settings, "controls") !== false
    readonly property int h: Theme.barHeight
    readonly property real progress: (p?.length ?? 0) > 0 ? Math.min(1, p.position / p.length) : 0

    shown: Players.hasTrack
    spacing: 10
    padding: flat ? BarConfig.flatPadding : Math.max(6, BarConfig.pillPadding - 10)
    onClicked: m => {
        if (m.button === Qt.MiddleButton) p?.togglePlaying();
        else Globals.toggleDashboard("media", screen);
    }
    onScrolled: w => w.angleDelta.y > 0 ? p?.previous() : p?.next()

    // Cover (player icon until it loads)
    ClippingRectangle {
        visible: root.showCover
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: root.h - 12
        implicitHeight: implicitWidth
        radius: Math.min(8, width / 3) * BarConfig.roundness + 2
        color: Theme.bg3
        BarText {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            icon: true
            text: Players.playerIcon(root.p)
            font.pixelSize: parent.width * 0.55
        }
        Image {
            id: cover
            anchors.fill: parent
            source: root.p?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 96
            asynchronous: true
        }
    }

    // Title / artist / progress
    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: root.maxTextWidth
        spacing: root.showArtist ? -1 : 2

        BarText {
            Layout.fillWidth: true
            Layout.maximumWidth: root.maxTextWidth
            text: root.showArtist ? (root.p?.trackTitle ?? "")
                : [root.p?.trackArtist, root.p?.trackTitle].filter(s => s).join(" - ")
            elide: Text.ElideRight
            font.pixelSize: root.showArtist ? BarConfig.textSize - 2 : BarConfig.textSize
            lineHeight: 0.95
        }
        BarText {
            visible: root.showArtist && text !== ""
            Layout.fillWidth: true
            Layout.maximumWidth: root.maxTextWidth
            text: root.p?.trackArtist ?? ""
            elide: Text.ElideRight
            opacity: 0.65
            font.pixelSize: BarConfig.textSize - 4
            font.weight: Font.Bold
        }
        Rectangle {
            visible: root.showProgress
            Layout.fillWidth: true
            Layout.topMargin: 2
            implicitHeight: 3
            radius: 1.5
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.2)
            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: parent.radius
                color: BarConfig.accentColor
                Behavior on width { NumberAnimation { duration: 900 } }
            }
        }
    }

    // Buttons
    RowLayout {
        visible: root.showControls
        Layout.alignment: Qt.AlignVCenter
        spacing: 0
        MediaButton { tint: root.iconColor; size: root.h - 14; icon: "\u{F04AE}"; enabled: root.p?.canGoPrevious ?? false; onClicked: root.p.previous() }
        MediaButton {
            tint: root.iconColor
            size: root.h - 12
            icon: root.p?.isPlaying ? "\u{F03E4}" : "\u{F040A}"
            filled: true
            onClicked: root.p.togglePlaying()
        }
        MediaButton { tint: root.iconColor; size: root.h - 14; icon: "\u{F04AD}"; enabled: root.p?.canGoNext ?? false; onClicked: root.p.next() }
    }
}

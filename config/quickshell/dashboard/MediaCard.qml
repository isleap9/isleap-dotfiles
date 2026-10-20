import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs

// Now playing: cover, title, controls, progress. Click the cover or title: the Media tab.
DashCard {
    id: card

    readonly property var p: Players.active
    readonly property bool tall: height >= 200

    Text {
        visible: !Players.hasTrack
        anchors.centerIn: parent
        text: "\u{F075B}  Nothing playing"
        color: Theme.fg2
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        font.weight: Font.Bold
    }

    GridLayout {
        visible: Players.hasTrack
        anchors.fill: parent
        columns: card.tall ? 1 : 3
        columnSpacing: 12
        rowSpacing: 8

        ClippingRectangle {
            Layout.preferredWidth: card.tall ? Math.min(card.height * 0.45, parent.width) : Math.min(parent.height, 80)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: card.tall ? Qt.AlignHCenter : Qt.AlignVCenter
            radius: 12
            color: Theme.bg3
            Image {
                anchors.fill: parent
                source: card.p?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 256
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Globals.dashboardTab = "media" }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            Text {
                Layout.fillWidth: true
                horizontalAlignment: card.tall ? Text.AlignHCenter : Text.AlignLeft
                text: card.p?.trackTitle ?? ""
                elide: Text.ElideRight
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Globals.dashboardTab = "media" }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: card.tall ? Text.AlignHCenter : Text.AlignLeft
                text: card.p?.trackArtist ?? ""
                elide: Text.ElideRight
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
            Seekbar {
                Layout.fillWidth: true
                Layout.topMargin: 4
                thickness: 4
                interactive: card.p?.canSeek ?? false
                value: (card.p?.length ?? 0) > 0 ? card.p.position / card.p.length : 0
                onMoved: v => { if (card.p) card.p.position = v * card.p.length; }
            }
        }

        RowLayout {
            Layout.alignment: card.tall ? Qt.AlignHCenter : Qt.AlignVCenter
            spacing: 2
            DashButton { icon: "\u{F04AE}"; enabled: card.p?.canGoPrevious ?? false; onClicked: card.p.previous() }
            DashButton {
                icon: card.p?.isPlaying ? "\u{F03E4}" : "\u{F040A}"
                filled: true
                size: 40
                onClicked: card.p.togglePlaying()
            }
            DashButton { icon: "\u{F04AD}"; enabled: card.p?.canGoNext ?? false; onClicked: card.p.next() }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs

// Big player: cover over a blurred backdrop, seek bar, controls, player and output pickers, volume.
Item {
    id: root

    readonly property MprisPlayer p: Players.active
    readonly property string art: p?.trackArtUrl ?? ""
    property bool outputsOpen: false

    implicitWidth: 6 * 128 + 5 * 8
    implicitHeight: 400

    ClippingRectangle {
        anchors.fill: parent
        radius: 18
        color: Theme.bg1

        // Backdrop: the cover, blurred and darkened
        Image {
            id: backdrop
            anchors.fill: parent
            source: root.art
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 256
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: backdrop
            visible: root.art !== "" && backdrop.status === Image.Ready
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.2
            opacity: 0.55
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.35) }
                GradientStop { position: 1; color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.85) }
            }
        }
    }

    // Nothing playing
    Column {
        visible: !Players.hasTrack
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u{F075B}"
            color: Theme.bg4
            font.family: Theme.iconFont
            font.pixelSize: 64
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
            font.weight: Font.Bold
        }
    }

    RowLayout {
        visible: Players.hasTrack
        anchors.fill: parent
        anchors.margins: 28
        spacing: 28

        // Cover
        ClippingRectangle {
            Layout.preferredWidth: 300
            Layout.preferredHeight: 300
            Layout.alignment: Qt.AlignVCenter
            radius: 20
            color: Theme.bg3
            Text {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                text: Players.playerIcon(root.p)
                color: Theme.fg2
                font.family: Theme.iconFont
                font.pixelSize: 96
            }
            Image {
                id: cover
                anchors.fill: parent
                source: root.art
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 600
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            // Players (when there's more than one)
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Players.list
                    Rectangle {
                        id: chip
                        required property MprisPlayer modelData
                        readonly property bool current: modelData === root.p
                        implicitWidth: chipRow.implicitWidth + 20
                        implicitHeight: 28
                        radius: 14
                        color: current ? Theme.accent : chipArea.containsMouse ? Theme.bg3 : Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.7)
                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: Players.playerIcon(chip.modelData)
                                color: chip.current ? Theme.bg0 : Theme.fg1
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.fontSize
                            }
                            Text {
                                text: chip.modelData.identity
                                color: chip.current ? Theme.bg0 : Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                                font.weight: Font.Bold
                            }
                        }
                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.chosen = chip.modelData.dbusName
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: root.p?.trackTitle ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: 28
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                text: root.p?.trackArtist ?? ""
                elide: Text.ElideRight
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 3
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.p?.trackAlbum ?? ""
                elide: Text.ElideRight
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }

            Item { Layout.fillHeight: true }

            // Seek bar with times
            Seekbar {
                id: seek
                Layout.fillWidth: true
                interactive: root.p?.canSeek ?? false
                value: (root.p?.length ?? 0) > 0 ? root.p.position / root.p.length : 0
                onMoved: v => { if (root.p) root.p.position = v * root.p.length; }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: Players.time(seek.shown * (root.p?.length ?? 0))
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.features: ({ tnum: 1 })
                }
                Text {
                    text: Players.time(root.p?.length ?? 0)
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.features: ({ tnum: 1 })
                }
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                DashButton {
                    icon: "\u{F049D}"
                    visible: root.p?.shuffleSupported ?? false
                    active: root.p?.shuffle ?? false
                    size: 40
                    onClicked: root.p.shuffle = !root.p.shuffle
                }
                DashButton { icon: "\u{F04AE}"; size: 48; enabled: root.p?.canGoPrevious ?? false; onClicked: root.p.previous() }
                DashButton {
                    icon: root.p?.isPlaying ? "\u{F03E4}" : "\u{F040A}"
                    filled: true
                    size: 64
                    onClicked: root.p.togglePlaying()
                }
                DashButton { icon: "\u{F04AD}"; size: 48; enabled: root.p?.canGoNext ?? false; onClicked: root.p.next() }
                DashButton {
                    visible: root.p?.loopSupported ?? false
                    readonly property int loop: root.p?.loopState ?? MprisLoopState.None
                    icon: loop === MprisLoopState.Track ? "\u{F0458}" : "\u{F0456}"
                    active: loop !== MprisLoopState.None
                    size: 40
                    onClicked: root.p.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist
                        : loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                }
            }

            Item { Layout.fillHeight: true }

            // Output device + volume
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    implicitWidth: Math.min(outRow.implicitWidth + 24, 260)
                    implicitHeight: 34
                    radius: 17
                    color: outArea.containsMouse || root.outputsOpen ? Theme.bg3 : Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.8)
                    Row {
                        id: outRow
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, 236)
                        spacing: 8
                        Text {
                            text: (Players.sink?.name ?? "").startsWith("bluez") ? "\u{F00B0}" : "\u{F04C3}"
                            color: Theme.fg1
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fontSize + 1
                        }
                        Text {
                            width: Math.min(implicitWidth, 200)
                            text: Players.sinkName(Players.sink)
                            elide: Text.ElideRight
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Font.Bold
                        }
                    }
                    MouseArea {
                        id: outArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.outputsOpen = !root.outputsOpen
                    }
                }

                Text {
                    text: (Players.sink?.audio?.muted ?? false) ? "\u{F075F}" : "\u{F057E}"
                    color: Theme.fg1
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.fontSize + 3
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (Players.sink?.audio) Players.sink.audio.muted = !Players.sink.audio.muted
                    }
                }
                Seekbar {
                    Layout.fillWidth: true
                    value: Players.sink?.audio?.volume ?? 0
                    onMoved: v => { if (Players.sink?.audio) Players.sink.audio.volume = v; }
                }
                Text {
                    text: Math.round((Players.sink?.audio?.volume ?? 0) * 100) + "%"
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.features: ({ tnum: 1 })
                }
            }
        }
    }

    // Output picker
    Rectangle {
        visible: root.outputsOpen
        x: 28 + 300 + 28
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28 + 42
        width: 360
        height: outList.implicitHeight + 12
        radius: 16
        color: Theme.bg2
        border.width: 1
        border.color: Theme.bg4

        Column {
            id: outList
            anchors.centerIn: parent
            width: parent.width - 12
            Repeater {
                model: Players.sinks
                Rectangle {
                    id: outItem
                    required property var modelData
                    readonly property bool current: modelData === Players.sink
                    width: outList.width
                    height: 38
                    radius: 12
                    color: itemArea.containsMouse ? Theme.bg3 : "transparent"
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        spacing: 10
                        Text {
                            text: outItem.current ? "\u{F012C}" : ""
                            width: 16
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fontSize
                        }
                        Text {
                            width: outItem.width - 50
                            text: Players.sinkName(outItem.modelData)
                            elide: Text.ElideRight
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: outItem.current ? Font.Bold : Font.Normal
                        }
                    }
                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Players.setSink(outItem.modelData); root.outputsOpen = false; }
                    }
                }
            }
        }
    }
}

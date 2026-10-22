import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.components

// Sound: output and input device, and a volume for each app that's playing
ColumnLayout {
    id: root

    spacing: 6

    PageHeader {
        title: "Sound"
        MIconButton {
            icon: "settings"
            onClicked: { Globals.quickSettingsOpen = false; Globals.run("pavucontrol"); }
        }
    }

    Flickable {
        id: audioFlick
        SmoothWheel { flick: audioFlick }
        MScrollBar { flick: audioFlick }
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(content.implicitHeight, 560)
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 2

            SectionLabel { text: "Apps" }
            Text {
                visible: Audio.streams.length === 0
                Layout.leftMargin: 14
                Layout.bottomMargin: 4
                text: "No apps are playing sound"
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
            Repeater {
                model: Audio.streams
                RowLayout {
                    id: app
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 6
                    implicitHeight: 52
                    spacing: 10
                    IconImage {
                        implicitSize: 30
                        source: Globals.appIcon(Audio.appIcon(app.modelData))
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: Audio.appName(app.modelData)
                            elide: Text.ElideRight
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Font.Bold
                        }
                        MSlider {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            trackHeight: 10
                            value: Math.min(1, app.modelData.audio?.volume ?? 0)
                            color: app.modelData.audio?.muted ? Theme.fg2 : Theme.accent
                            onMoved: v => Audio.setVolume(app.modelData, v)
                        }
                    }
                    MIconButton {
                        icon: Audio.volumeIcon(app.modelData.audio?.volume ?? 0, app.modelData.audio?.muted ?? false)
                        size: 36
                        onClicked: Audio.toggleMute(app.modelData)
                    }
                }
            }

            SectionLabel { text: "Output" }
            Repeater {
                model: Audio.sinks
                ListRow {
                    required property var modelData
                    icon: Audio.sinkIcon(modelData)
                    title: Audio.name(modelData)
                    selected: modelData === Audio.sink
                    onClicked: Audio.setSink(modelData)
                }
            }

            SectionLabel { text: "Input" }
            Repeater {
                model: Audio.sources
                ListRow {
                    required property var modelData
                    icon: "mic"
                    title: Audio.name(modelData)
                    selected: modelData === Audio.source
                    onClicked: Audio.setSource(modelData)
                }
            }
        }
    }
}

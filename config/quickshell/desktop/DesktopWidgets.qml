import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs

// Desktop widgets (Material 3): a big clock, now playing and weather, drawn on the wallpaper
// (under your windows). Settings → Desktop: which ones, where, and on which monitors.
Variants {
    model: Quickshell.screens

    Scope {
        id: scope
        required property ShellScreen modelData
        readonly property bool wanted: Config.desktop.enabled
            && (Config.desktop.screens === "all" || modelData === Globals.mainScreen)

        LazyLoader {
            active: scope.wanted

            PanelWindow {
                id: win
                screen: scope.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.namespace: "quickshell-desktop"
                // Only the widgets take clicks
                mask: Region { item: box }

                readonly property string pos: Config.desktop.position
                readonly property int edge: 80

                SystemClock { id: clock; precision: SystemClock.Minutes }

                ColumnLayout {
                    id: box
                    spacing: 20
                    x: win.pos.endsWith("left") ? win.edge : win.pos.endsWith("right") ? win.width - width - win.edge : (win.width - width) / 2
                    y: win.pos.startsWith("top") ? win.edge + Theme.barHeight : win.pos.startsWith("bottom") ? win.height - height - win.edge : (win.height - height) / 2
                    readonly property int align: win.pos.endsWith("left") ? Qt.AlignLeft : win.pos.endsWith("right") ? Qt.AlignRight : Qt.AlignHCenter

                    // ── Clock ──
                    ColumnLayout {
                        visible: Config.desktop.clock
                        Layout.alignment: box.align
                        spacing: -8
                        Text {
                            Layout.alignment: box.align
                            // Qt only uses 12-hour time with AP in the format, so cut the AM/PM off afterwards
                            text: Config.bar.clock24h ? Qt.formatTime(clock.date, "HH:mm") : Qt.formatTime(clock.date, "h:mm AP").split(" ")[0]
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: Config.desktop.clockSize
                            font.weight: Font.Bold
                            font.features: ({ tnum: 1 })
                            style: Text.Raised
                            styleColor: Qt.rgba(0, 0, 0, 0.25)
                        }
                        Text {
                            Layout.alignment: box.align
                            text: Qt.formatDate(clock.date, "dddd, MMMM d")
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Math.round(Config.desktop.clockSize * 0.2)
                            font.weight: Font.Bold
                            style: Text.Raised
                            styleColor: Qt.rgba(0, 0, 0, 0.3)
                        }
                    }

                    RowLayout {
                        Layout.alignment: box.align
                        spacing: 12

                        // ── Weather ──
                        Rectangle {
                            visible: Config.desktop.weather && WeatherData.ready
                            implicitWidth: wRow.implicitWidth + 40
                            implicitHeight: 80
                            radius: 40
                            color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.82)
                            RowLayout {
                                id: wRow
                                anchors.centerIn: parent
                                spacing: 12
                                Text {
                                    text: WeatherData.icon(WeatherData.current?.code, WeatherData.current?.isDay)
                                    color: Theme.accent
                                    font.family: Theme.iconFont
                                    font.variableAxes: Theme.iconAxes
                                    font.pixelSize: 36
                                }
                                ColumnLayout {
                                    spacing: 0
                                    Text {
                                        text: WeatherData.temp(WeatherData.current?.temp)
                                        color: Theme.fg1
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize + 9
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: WeatherData.describe(WeatherData.current?.code)
                                        color: Theme.fg2
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                    }
                                }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Globals.toggleDashboard("weather", win.screen) }
                        }

                        // ── Now playing ──
                        Rectangle {
                            visible: Config.desktop.media && Players.hasTrack
                            implicitWidth: 380
                            implicitHeight: 80
                            radius: 40
                            color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.82)
                            readonly property var p: Players.active

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 14
                                spacing: 12
                                ClippingRectangle {
                                    implicitWidth: 60; implicitHeight: 60
                                    radius: 30
                                    color: Theme.bg3
                                    Image {
                                        anchors.fill: parent
                                        source: Players.active?.trackArtUrl ?? ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 120
                                        asynchronous: true
                                        // Spins while playing, like a record
                                        RotationAnimation on rotation {
                                            from: 0; to: 360; duration: 12000
                                            loops: Animation.Infinite
                                            running: Players.active?.isPlaying ?? false
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Globals.toggleDashboard("media", win.screen) }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        Layout.fillWidth: true
                                        text: Players.active?.trackTitle ?? ""
                                        elide: Text.ElideRight
                                        color: Theme.fg1
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: Players.active?.trackArtist ?? ""
                                        elide: Text.ElideRight
                                        color: Theme.fg2
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 2
                                    }
                                }
                                Rectangle {
                                    implicitWidth: 48; implicitHeight: 48; radius: 24
                                    color: Theme.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: Players.active?.isPlaying ? "pause" : "play_arrow"
                                        color: Theme.bg0
                                        font.family: Theme.iconFont
                                        font.variableAxes: Theme.iconAxes
                                        font.pixelSize: 24
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Players.active?.togglePlaying() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

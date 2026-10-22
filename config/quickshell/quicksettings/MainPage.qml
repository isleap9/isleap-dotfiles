import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import qs
import qs.components
import qs.notifications

// Quick settings main page (layout after tripathiji1312/quickshell, MIT):
// clock, toggle tiles, volume + mic, CPU/RAM/Disk, now playing, notifications
ColumnLayout {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiNet: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btConnected: (bt?.devices.values ?? []).filter(d => d.connected)

    spacing: 14

    // Stats only poll while something shows them
    Component.onCompleted: SysStats.use()
    Component.onDestruction: SysStats.release()

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ── Clock + date, settings / lock / power ──
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 4
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                text: Config.bar.clock24h ? Qt.formatDateTime(clock.date, "HH:mm")
                    : Qt.formatDateTime(clock.date, "hh:mm AP").split(" ")[0]
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 20
                font.weight: Font.Bold
                font.features: ({ tnum: 1 })
            }
            Text {
                text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }
        MIconButton { icon: "settings"; onClicked: { Globals.quickSettingsOpen = false; Globals.openSettings(""); } }
        MIconButton {
            icon: "lock"
            onClicked: { Globals.quickSettingsOpen = false; Globals.run(Quickshell.env("HOME") + "/.config/quickshell/scripts/lock.sh"); }
        }
        MIconButton { icon: "power_settings_new"; onClicked: { Globals.closeAll(); Globals.powerMenuOpen = true; } }
    }

    // ── Tiles ──
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        MTile {
            Layout.fillWidth: true
            icon: root.wifi ? (root.wifiNet ? "wifi" : root.wifi && Networking.wifiEnabled ? "signal_wifi_0_bar" : "wifi_off") : "lan"
            label: root.wifi ? "Wi-Fi" : "Network"
            status: root.wifiNet ? root.wifiNet.name : root.wired ? "Ethernet" : root.wifi && Networking.wifiEnabled ? "Not connected" : root.wifi ? "Off" : "Offline"
            on: root.wifi ? Networking.wifiEnabled : root.wired !== null
            hasMore: true
            onToggled: if (root.wifi) Networking.wifiEnabled = !Networking.wifiEnabled; else Globals.quickSettingsPage = "wifi"
            onMore: Globals.quickSettingsPage = "wifi"
        }
        MTile {
            Layout.fillWidth: true
            icon: root.bt?.enabled ? (root.btConnected.length ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
            label: "Bluetooth"
            status: !root.bt ? "No adapter" : !root.bt.enabled ? "Off" : root.btConnected.length ? root.btConnected[0].name : "On"
            on: root.bt?.enabled ?? false
            available: root.bt !== null
            hasMore: true
            onToggled: root.bt.enabled = !root.bt.enabled
            onMore: Globals.quickSettingsPage = "bluetooth"
        }
        MTile {
            Layout.fillWidth: true
            icon: Notifs.dnd ? "notifications_off" : "notifications"
            label: "Do not disturb"
            status: Notifs.dnd ? "On" : "Off"
            on: Notifs.dnd
            onToggled: Notifs.dnd = !Notifs.dnd
        }
        MTile {
            Layout.fillWidth: true
            icon: "nightlight"
            label: "Night light"
            status: NightLight.status
            on: NightLight.enabled
            available: NightLight.installed
            hasMore: true
            onToggled: NightLight.toggle()
            onMore: { Globals.quickSettingsOpen = false; Globals.openSettings("desktop"); }
        }
        MTile {
            Layout.fillWidth: true
            icon: Globals.keepAwake ? "coffee" : "coffee"
            label: "Keep awake"
            status: Globals.keepAwake ? "Screen stays on" : "Off"
            on: Globals.keepAwake
            onToggled: Globals.setKeepAwake(!Globals.keepAwake)
        }
        MTile {
            Layout.fillWidth: true
            icon: Audio.micMuted ? "mic_off" : "mic"
            label: "Microphone"
            status: Audio.micMuted ? "Muted" : "On"
            on: !Audio.micMuted
            available: Audio.source !== null
            onToggled: Audio.toggleMute(Audio.source)
        }
        MTile {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            icon: "screenshot_monitor"
            label: "Screenshot"
            status: "Capture a region"
            hasMore: true
            onToggled: { Globals.quickSettingsOpen = false; Globals.run("sleep 0.3; hyprshot -m region --output-folder ~/Pictures/Screenshots"); }
            onMore: { Globals.quickSettingsOpen = false; Globals.openControlCenter("capture"); }
        }
    }

    // ── Volume / mic ──
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sliders.implicitHeight + 24
        radius: 24
        color: BarConfig.surface(Theme.bg1)

        ColumnLayout {
            id: sliders
            anchors.centerIn: parent
            width: parent.width - 24
            spacing: 6

            RowLayout {
                spacing: 6
                MIconButton {
                    icon: Audio.volumeIcon(Audio.volume, Audio.muted)
                    selected: !Audio.muted
                    onClicked: Audio.toggleMute(Audio.sink)
                }
                MSlider {
                    Layout.fillWidth: true
                    value: Math.min(1, Audio.volume)
                    color: Audio.muted ? Theme.fg2 : Theme.accent
                    onMoved: v => Audio.setVolume(Audio.sink, v)
                }
                Text {
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Audio.volume * 100) + "%"
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.features: ({ tnum: 1 })
                }
                MIconButton { icon: "chevron_right"; size: 32; onClicked: Globals.quickSettingsPage = "audio" }
            }
            RowLayout {
                spacing: 6
                MIconButton {
                    icon: Audio.micMuted ? "mic_off" : "mic"
                    selected: !Audio.micMuted
                    enabled: Audio.source !== null
                    onClicked: Audio.toggleMute(Audio.source)
                }
                MSlider {
                    Layout.fillWidth: true
                    value: Math.min(1, Audio.micVolume)
                    interactive: Audio.source !== null
                    color: Audio.micMuted ? Theme.fg2 : Theme.accent
                    onMoved: v => Audio.setVolume(Audio.source, v)
                }
                Text {
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Audio.micVolume * 100) + "%"
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.features: ({ tnum: 1 })
                }
                MIconButton { icon: "chevron_right"; size: 32; onClicked: Globals.quickSettingsPage = "audio" }
            }
        }
    }

    // ── CPU / RAM / Disk ──
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 78
        radius: 24
        color: BarConfig.surface(Theme.bg1)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            Repeater {
                model: [
                    { icon: "memory", label: "CPU", value: SysStats.cpu },
                    { icon: "memory_alt", label: "RAM", value: SysStats.memPercent },
                    { icon: "hard_drive", label: "Disk", value: SysStats.diskPercent }
                ]
                Item {
                    id: stat
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Divider between stats
                    Rectangle {
                        visible: stat.index > 0
                        width: 1
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 8; bottomMargin: 8 }
                        color: Theme.bg3
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: stat.modelData.icon
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.variableAxes: Theme.iconAxes
                                font.pixelSize: Theme.fontSize + 1
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(stat.modelData.value) + "%"
                                color: Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 1
                                font.weight: Font.Bold
                                font.features: ({ tnum: 1 })
                            }
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 56
                            height: 4
                            radius: 2
                            color: Theme.bg3
                            Rectangle {
                                width: parent.width * Math.min(1, stat.modelData.value / 100)
                                height: parent.height
                                radius: 2
                                color: stat.modelData.value > 85 ? Theme.red : Theme.accent
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: stat.modelData.label
                            color: Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                }
            }
        }
    }

    // ── Now playing (only while something plays) ──
    Rectangle {
        id: media
        readonly property var p: Players.active
        visible: Players.hasTrack
        Layout.fillWidth: true
        implicitHeight: 88
        radius: 24
        color: BarConfig.surface(Theme.bg1)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            ClippingRectangle {
                implicitWidth: 64
                implicitHeight: 64
                radius: 14
                color: Theme.bg3
                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "music_note"
                    color: Theme.fg2
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: 26
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: media.p?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 128
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: media.p?.trackTitle ?? ""
                    elide: Text.ElideRight
                    color: Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Bold
                }
                Text {
                    Layout.fillWidth: true
                    text: media.p?.trackArtist ?? ""
                    elide: Text.ElideRight
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
            }
            MIconButton { icon: "skip_previous"; size: 36; enabled: media.p?.canGoPrevious ?? false; onClicked: media.p.previous() }
            MIconButton { icon: media.p?.isPlaying ? "pause" : "play_arrow"; style: "filled"; size: 44; onClicked: media.p.togglePlaying() }
            MIconButton { icon: "skip_next"; size: 36; enabled: media.p?.canGoNext ?? false; onClicked: media.p.next() }
        }
    }

    // ── Notifications ──
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: notifCol.implicitHeight + 28
        radius: 24
        color: BarConfig.surface(Theme.bg1)
        Behavior on implicitHeight { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: notifCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                spacing: 8
                Text {
                    text: "Notifications"
                    color: Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    visible: Notifs.count > 0
                    implicitHeight: 20
                    implicitWidth: Math.max(20, countText.implicitWidth + 10)
                    radius: 10
                    color: Theme.accent
                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: Notifs.count
                        color: Theme.bg0
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                        font.weight: Font.Bold
                    }
                }
                Item { Layout.fillWidth: true }
                // "Clear all" text button
                Rectangle {
                    visible: Notifs.count > 0
                    implicitHeight: 30
                    implicitWidth: clearText.implicitWidth + 20
                    radius: 15
                    color: clearArea.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        font.weight: Font.Medium
                    }
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            // Empty state
            RowLayout {
                visible: Notifs.count === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                spacing: 8
                Text {
                    text: Notifs.dnd ? "notifications_off" : "notifications_none"
                    color: Theme.fg2
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: Theme.fontSize + 4
                }
                Text {
                    text: Notifs.dnd ? "Do not disturb is on" : "You're all caught up"
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
            }

            ListView {
                SmoothWheel { flick: notifList }
                MScrollBar { flick: notifList }
                id: notifList
                visible: Notifs.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 300)
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel { values: Array.from(Notifs.list) }

                delegate: Item {
                    id: slot
                    required property var modelData
                    width: ListView.view.width - (ListView.view.contentHeight > ListView.view.height ? 12 : 0)
                    height: ncard.implicitHeight

                    property real enter: 1
                    property real leave: 0
                    property real dragX: 0
                    readonly property int exitSign: dragX < 0 ? -1 : 1

                    NotificationCard {
                        id: ncard
                        notif: slot.modelData
                        width: parent.width
                        surfaceColor: Theme.bg2
                        x: slot.dragX + slot.leave * slot.exitSign * (slot.width + 40)
                        rotation: slot.dragX * 0.015
                        opacity: slot.enter * (1 - slot.leave)
                                 * (1 - Math.min(Math.abs(slot.dragX) / slot.width, 1) * 0.6)
                    }
                    // Swipe sideways to dismiss
                    DragHandler {
                        target: null
                        yAxis.enabled: false
                        onTranslationChanged: if (active) slot.dragX = translation.x * 0.8
                        onActiveChanged: {
                            if (active) { snapBack.stop(); return; }
                            if (Math.abs(slot.dragX) > slot.width * 0.3 && slot.modelData) slot.modelData.dismiss();
                            else snapBack.start();
                        }
                    }
                    NumberAnimation {
                        id: snapBack
                        target: slot; property: "dragX"; to: 0
                        duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.3
                    }
                }

                add: Transition {
                    NumberAnimation { property: "enter"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
                }
                remove: Transition {
                    NumberAnimation { property: "leave"; to: 1; duration: 180; easing.type: Easing.InCubic }
                }
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "enter"; to: 1; duration: 200 }
                }
            }
        }
    }
}

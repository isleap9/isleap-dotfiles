import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import qs
import qs.components

// Quick settings main page: you, volume + mic, and toggle tiles
ColumnLayout {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiNet: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btConnected: (bt?.devices.values ?? []).filter(d => d.connected)

    spacing: 14

    // ── You ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ClippingRectangle {
            implicitWidth: 48
            implicitHeight: 48
            radius: 24
            color: Theme.accent
            Text {
                anchors.centerIn: parent
                visible: face.status !== Image.Ready
                text: Quickshell.env("USER").charAt(0).toUpperCase()
                color: Theme.bg0
                font.family: Theme.font
                font.pixelSize: 22
                font.weight: Font.Black
            }
            Image {
                id: face
                anchors.fill: parent
                source: Avatar.source
                cache: false
                fillMode: Image.PreserveAspectCrop
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: Quickshell.env("USER")
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                text: "Up " + SysStats.duration(SysStats.uptime)
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }
        MIconButton { icon: "settings"; style: "tonal"; onClicked: { Globals.quickSettingsOpen = false; Globals.openSettings(""); } }
        MIconButton {
            icon: "lock"; style: "tonal"
            onClicked: { Globals.quickSettingsOpen = false; Globals.run(Quickshell.env("HOME") + "/.config/quickshell/scripts/lock.sh"); }
        }
        MIconButton { icon: "power_settings_new"; style: "tonal"; onClicked: { Globals.closeAll(); Globals.powerMenuOpen = true; } }
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
    }
}

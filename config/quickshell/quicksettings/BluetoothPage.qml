import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs
import qs.components

// Bluetooth: on/off, your devices (connect / disconnect / forget), and scanning for new ones (pair)
ColumnLayout {
    id: root

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var all: bt?.devices.values ?? []
    readonly property var paired: all.filter(d => d.paired).sort((a, b) => b.connected - a.connected)
    readonly property var found: all.filter(d => !d.paired && d.name)

    spacing: 8

    // Look for new devices while this page is open
    Binding { target: root.bt; property: "discovering"; value: true; when: root.bt?.enabled ?? false }

    function icon(d) {
        const i = d?.icon ?? "";
        if (i.includes("headset") || i.includes("headphone")) return "headphones";
        if (i.includes("audio")) return "speaker";
        if (i.includes("keyboard")) return "keyboard";
        if (i.includes("mouse")) return "mouse";
        if (i.includes("phone")) return "smartphone";
        if (i.includes("gaming") || i.includes("joystick")) return "sports_esports";
        return "bluetooth";
    }
    function state(d) {
        if (d.pairing) return "Pairing…";
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…";
        const battery = d.batteryAvailable ? ` · ${Math.round(d.battery * 100)}%` : "";
        return (d.connected ? "Connected" : d.paired ? "Paired" : "Tap to pair") + battery;
    }

    PageHeader {
        title: "Bluetooth"
        MSwitch {
            visible: root.bt !== null
            checked: root.bt?.enabled ?? false
            onToggled: root.bt.enabled = !root.bt.enabled
        }
    }

    Text {
        visible: root.bt === null || !root.bt.enabled
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.bottomMargin: 8
        text: root.bt === null ? "No Bluetooth adapter on this computer" : "Bluetooth is off"
        color: Theme.fg2
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
    }

    ColumnLayout {
        visible: root.bt?.enabled ?? false
        Layout.fillWidth: true
        spacing: 2

        SectionLabel { visible: root.paired.length > 0; text: "Your devices" }
        Repeater {
            model: root.paired
            ListRow {
                required property var modelData
                icon: root.icon(modelData)
                title: modelData.name
                subtitle: root.state(modelData)
                selected: modelData.connected
                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                MIconButton { icon: "delete"; size: 32; onClicked: parent.parent.parent.modelData.forget() }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            SectionLabel { text: "Available" }
            Text {
                visible: root.bt?.discovering ?? false
                Layout.rightMargin: 14
                text: "Searching…"
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }
        Repeater {
            model: root.found
            ListRow {
                required property var modelData
                icon: root.icon(modelData)
                title: modelData.name
                subtitle: root.state(modelData)
                onClicked: modelData.pairing ? modelData.cancelPair() : modelData.pair()
            }
        }
    }
}

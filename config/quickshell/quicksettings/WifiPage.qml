import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs
import qs.components

// Wi-Fi: on/off, networks by signal strength, connect (asks for the password when needed), forget.
// Also shows wired connections.
ColumnLayout {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevices: Networking.devices.values.filter(d => d.type === DeviceType.Wired)
    readonly property var networks: (wifi?.networks.values ?? []).filter(n => n.name)
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    property var asking: null            // network waiting for a password
    property string error: ""

    spacing: 8

    // Scan while this page is open
    Binding { target: root.wifi; property: "scannerEnabled"; value: true; when: root.wifi !== null }

    PageHeader {
        title: "Network"
        MSwitch {
            visible: root.wifi !== null
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    // Wired
    SectionLabel { visible: root.wiredDevices.length > 0; text: "Ethernet" }
    Repeater {
        model: root.wiredDevices
        ListRow {
            required property var modelData
            icon: "lan"
            title: modelData.name
            subtitle: modelData.connected ? "Connected" : "Cable unplugged"
            selected: modelData.connected
            clickable: false
        }
    }

    // Wi-Fi
    SectionLabel { text: "Wi-Fi" }
    Text {
        visible: root.wifi === null || !Networking.wifiEnabled
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.bottomMargin: 8
        text: root.wifi === null ? "No Wi-Fi adapter on this computer" : "Wi-Fi is off"
        color: Theme.fg2
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
    }
    Flickable {
        id: wifiFlick
        SmoothWheel { flick: wifiFlick }
        MScrollBar { flick: wifiFlick }
        visible: root.wifi !== null && Networking.wifiEnabled
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, 380)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: root.networks
                ColumnLayout {
                    id: net
                    required property var modelData
                    readonly property bool secured: modelData.security !== WifiSecurityType.Open
                    readonly property int bars: Math.min(4, Math.floor(modelData.signalStrength * 5))
                    Layout.fillWidth: true
                    spacing: 4

                    ListRow {
                        icon: (net.secured ? ["wifi_lock", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "wifi"]
                            : ["signal_wifi_0_bar", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "wifi"])[net.bars]
                        title: net.modelData.name
                        subtitle: net.modelData.connected ? "Connected"
                            : net.modelData.stateChanging ? "Connecting…"
                            : net.modelData.known ? "Saved" : net.secured ? "Secured" : "Open"
                        selected: net.modelData.connected
                        onClicked: {
                            root.error = "";
                            if (net.modelData.connected) net.modelData.disconnect();
                            else if (net.modelData.known || !net.secured) net.modelData.connect();
                            else root.asking = root.asking === net.modelData ? null : net.modelData;
                        }
                        MIconButton {
                            visible: net.modelData.known
                            icon: "delete"
                            size: 32
                            onClicked: net.modelData.forget()
                        }
                    }

                    // Password
                    RowLayout {
                        visible: root.asking === net.modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        Layout.rightMargin: 8
                        Layout.bottomMargin: 6
                        spacing: 8
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: 22
                            color: Theme.bg2
                            border.width: pw.activeFocus ? 2 : 0
                            border.color: Theme.accent
                            TextInput {
                                id: pw
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                color: Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                focus: root.asking === net.modelData
                                onAccepted: connectBtn.clicked()
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: pw.text === ""
                                    text: "Password"
                                    color: Theme.fg2
                                    font: pw.font
                                }
                            }
                        }
                        MIconButton {
                            id: connectBtn
                            icon: "arrow_forward"
                            style: "filled"
                            enabled: pw.text.length >= 8
                            onClicked: {
                                net.modelData.connectWithPsk(pw.text);
                                pw.text = "";
                                root.asking = null;
                            }
                        }
                    }

                    Connections {
                        target: net.modelData
                        function onConnectionFailed(reason) {
                            root.error = `Couldn't connect to ${net.modelData.name}: ${ConnectionFailReason.toString(reason)}`;
                        }
                    }
                }
            }
        }
    }
    Text {
        visible: root.error !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 14
        wrapMode: Text.Wrap
        text: root.error
        color: Theme.red
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 3
    }
}

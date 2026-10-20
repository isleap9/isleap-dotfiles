import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.components

// Network status via nmcli. Ethernet: 󰈀, Wi-Fi: SSID, offline: 󰈂
Pill {
    id: root
    shown: Config.bar.modules.network

    property string type: ""      // "ethernet", "wifi" or ""
    property string device: ""
    property string connection: ""

    readonly property string icon: type === "ethernet" ? "󰈀" : type === "wifi" ? "󰖩" : "󰈂"

    onClicked: Quickshell.execDetached(["kitty", "-e", "nmtui"])

    Process {
        id: proc
        running: true
        command: ["nmcli", "-t", "-f", "TYPE,STATE,DEVICE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                // First connected ethernet/wifi device wins
                const rows = text.trim().split("\n").map(l => l.split(":"));
                const up = rows.find(r => (r[0] === "ethernet" || r[0] === "wifi") && r[1] === "connected");
                root.type = up ? up[0] : "";
                root.device = up ? up[2] : "";
                root.connection = up ? up.slice(3).join(":") : "";
            }
        }
    }

    // Refresh whenever NetworkManager reports a change
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: proc.running = true }
    }

    BarText { icon: true; text: root.icon }
    BarText { visible: root.type === "wifi"; text: root.connection }

    Tooltip {
        target: root
        show: root.hovered
        text: root.type ? `${root.connection} (${root.device})` : "Disconnected"
    }
}

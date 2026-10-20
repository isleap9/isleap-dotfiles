pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Caps lock state and the keyboard layout (for the OSD)
Singleton {
    id: root

    property bool capsLock: false
    property string layout: ""            // full name, e.g. "English (UK)"
    signal layoutSwitched

    // Caps lock: the keyboard's LED
    property string ledPath: ""
    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: root.ledPath = text.trim() ? text.trim() + "/brightness" : "" }
    }
    FileView {
        id: led
        path: root.ledPath
        onLoaded: root.capsLock = text().trim() !== "0"
    }
    Timer {
        interval: 200
        running: root.ledPath !== ""
        repeat: true
        onTriggered: led.reload()
    }

    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards;
                    root.layout = (kbs.find(k => k.main) ?? kbs[0]).active_keymap;
                } catch (e) {}
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const parts = event.data.split(",");
            const l = parts[parts.length - 1];
            if (l !== root.layout) {
                root.layout = l;
                root.layoutSwitched();
            }
        }
    }
}

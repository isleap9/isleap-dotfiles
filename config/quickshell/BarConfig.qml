pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which bar layout is active: default, default2, minimal or sleek.
// Stored in the same file Waybar used, so the old choice carries over.
Singleton {
    id: root

    readonly property string file: Quickshell.env("HOME") + "/.config/waybar/current-layout"
    readonly property var layouts: ["default", "default2", "minimal", "sleek"]
    property string layout: "default"

    // Padding for modules that sit inside a shared pill (no background of their own)
    readonly property int flatPadding: layout === "sleek" ? 5 : 0

    function set(name) {
        if (!layouts.includes(name)) return;
        layout = name;
        store.setText(name + "\n");
    }

    FileView {
        id: store
        path: root.file
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const name = text().trim();
            root.layout = root.layouts.includes(name) ? name : "default";
        }
    }

    // qs ipc call bar layout sleek
    IpcHandler {
        target: "bar"
        function layout(name: string): void { root.set(name); }
        function next(): void {
            root.set(root.layouts[(root.layouts.indexOf(root.layout) + 1) % root.layouts.length]);
        }
    }
}

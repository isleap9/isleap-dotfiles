pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// All user settings, saved to ~/.config/quickshell/config.json.
// Edited by the Settings app; anything missing from the file uses the defaults below.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/config.json"

    property alias appearance: adapter.appearance
    property alias bar: adapter.bar
    property alias notifications: adapter.notifications
    property alias launcher: adapter.launcher
    property alias powerMenu: adapter.powerMenu
    property alias monitors: adapter.monitors
    property alias dashboard: adapter.dashboard

    // Put every setting back to its default
    function reset() {
        file.setText("{}\n");
        file.reload();
    }

    // Several settings often change at once (e.g. a bar preset). Save them in one go, and only
    // re-read the file a moment later, so a reload can't undo changes that weren't saved yet.
    Timer { id: saveTimer; interval: 150; onTriggered: file.writeAdapter() }
    Timer { id: reloadTimer; interval: 400; onTriggered: if (!saveTimer.running) file.reload() }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: saveTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string font: "Google Sans Display"
                property string iconFont: "JetBrainsMono Nerd Font Propo"
                property int fontSize: 15
                property real animationSpeed: 1.0   // 0 = off, 0.5 = fast, 1 = normal, 2 = slow
            }

            property JsonObject bar: JsonObject {
                property int height: 40
                property int topMargin: 16
                property int sideMargin: 30
                property int spacing: 18
                property bool clock24h: false
                property string weatherCity: "Bari"
                property int minWorkspaces: 4

                // Which bar is shown: default, default2, minimal, sleek (imported from Waybar) or custom
                property string preset: ""

                // ── The Custom bar (the only editable one) ──
                property string position: "top"       // top, bottom
                property string style: "floating"     // floating (pills) or solid (attached bar)
                // Widgets in each lane, in order: [{ type: "clock", ...widget options }]
                property var lanes: ({ left: [], center: [], right: [] })
                // Lanes drawn as one shared pill
                property var grouped: ({ left: false, center: false, right: false })
                property int customVersion: 0         // 1 = Custom bar already set up
                // Custom bar look: colors, border, roundness, density, sizes (see BarConfig.lookDefaults)
                property var look: ({})

                // Old per-module switches (replaced by lanes; kept so old config files still load)
                property JsonObject modules: JsonObject {
                    property bool weather: true
                    property bool clock: true
                    property bool cava: true
                    property bool media: true
                    property bool tray: true
                    property bool language: true
                    property bool volume: true
                    property bool network: true
                    property bool notifications: true
                    property bool power: true
                }
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 5          // seconds a popup stays up
                property string position: "top-right"   // top-right, top-left, bottom-right, bottom-left
                property int maxPopups: 4
            }

            property JsonObject launcher: JsonObject {
                property int width: 620
                property int height: 520
                property bool showDescriptions: true
            }

            property JsonObject powerMenu: JsonObject {
                property bool confirm: true
            }

            property JsonObject dashboard: JsonObject {
                // Overview cards in order: [{ id: "clock", w: 2, h: 1 }] (empty = the default layout)
                property var cards: []
                property string units: "metric"       // metric (°C, km/h) or imperial (°F, mph)
            }

            property JsonObject monitors: JsonObject {
                property string main: ""              // connector name, e.g. "DP-3" ("" = the biggest screen)
                property var barHidden: []            // monitors with no bar
                property string popups: "focused"     // where popups open: "focused" or "main" monitor
            }
        }
    }
}

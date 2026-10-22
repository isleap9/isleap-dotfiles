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
    property alias osd: adapter.osd
    property alias nightLight: adapter.nightLight
    property alias desktop: adapter.desktop
    property alias session: adapter.session
    property alias icons: adapter.icons
    property alias panels: adapter.panels
    property alias animations: adapter.animations
    property alias files: adapter.files

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
                property string iconFont: "Material Symbols Rounded"   // icon style: Material Symbols Rounded / Outlined / Sharp
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
                property bool hero: true              // current wallpaper banner on top
                property int heroHeight: 180          // added on top of `height`
            }

            property JsonObject powerMenu: JsonObject {
                property bool confirm: true
            }

            property JsonObject dashboard: JsonObject {
                // Overview cards in order: [{ id: "clock", w: 2, h: 1 }] (empty = the default layout)
                property var cards: []
                property string units: "metric"       // metric (°C, km/h) or imperial (°F, mph)
                property string openOn: "last"        // tab SUPER+A opens: last, overview, media, weather, wallpaper
            }

            property JsonObject icons: JsonObject {
                property bool filled: false           // always filled (otherwise outlined, filling on hover/active)
                property int weight: 400              // 100–700
            }

            property JsonObject panels: JsonObject {
                property int radius: 28               // corners of the dashboard, quick settings, menus
                property int joint: 24                // curved joint where a panel meets the bar
                property bool hoverCards: true        // clock calendar, weather forecast… on hover
                property int hoverDelay: 350          // ms before a hover card opens
            }

            // File explorer (qs ipc call files toggle)
            property JsonObject files: JsonObject {
                property string view: "grid"          // grid, list
                property bool showHidden: false
                property string sortBy: "name"        // name, modified, size, type
                property bool sortReversed: false
                property int iconSize: 72             // grid icon size, Ctrl+scroll to zoom
                property bool thumbnails: true        // image / video previews
                property var pinned: []               // folders pinned to the sidebar
            }

            // Survives shell reloads and restarts
            property JsonObject session: JsonObject {
                property bool keepAwake: false        // no screen blanking / locking / suspend
            }

            property JsonObject desktop: JsonObject {
                property bool enabled: true
                property bool clock: true
                property int clockSize: 140
                property bool media: true
                property bool weather: true
                property string position: "top-left"   // top-left, top, center, bottom-left, bottom-right
                property string screens: "main"        // main, all
            }

            property JsonObject nightLight: JsonObject {
                property bool enabled: false
                property int temperature: 4000        // Kelvin: lower = warmer
                property string schedule: "sun"       // always, sun (sunset → sunrise), custom
                property string from: "20:00"
                property string to: "07:00"
            }

            // How each panel opens: slide, bounce, scale, fade or none (see Motion.qml)
            property JsonObject animations: JsonObject {
                property bool closing: true           // play a reverse animation when closing
                property string popups: "bounce"      // notification popups
                property string notifCenter: "slide"
                property string dashboard: "slide"
                property string quickSettings: "slide"
                property string trayMenu: "slide"
                property string launcher: "scale"
                property string controlCenter: "scale"
                property string powerMenu: "fade"
                property string overview: "scale"
                property string osd: "scale"
            }

            property JsonObject osd: JsonObject {
                property bool enabled: true           // volume / mic / caps lock / layout popups
                property string position: "bottom"    // bottom, top, center
                property int duration: 1600           // ms
                property bool volume: true
                property bool mic: true
                property bool caps: true
                property bool layout: true
            }

            property JsonObject monitors: JsonObject {
                property string main: ""              // connector name, e.g. "DP-3" ("" = the biggest screen)
                property var barHidden: []            // monitors with no bar
                property string popups: "focused"     // where popups open: "focused" or "main" monitor
            }
        }
    }
}

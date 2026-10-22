pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colors come from your existing Waybar theme file, so the theme switcher
// (SUPER+SHIFT+T) keeps working. Names match the @define-color names,
// with dashes turned into camelCase (special-white -> specialWhite).
Singleton {
    id: root

    readonly property string themeFile: Quickshell.env("HOME") + "/.config/waybar/themes/active.css"

    // Fallback values (E-Ink Dark)
    readonly property var defaults: ({
        bg0: "#1a1a1a", bg1: "#242424", bg2: "#2e2e2e", bg3: "#383838", bg4: "#444444",
        fg1: "#e8e8e8", fg2: "#909090", surface: "#808080",
        red: "#cc3333", orange: "#cc6633", yellow: "#888800", green: "#336633",
        cyan: "#336666", aqua: "#336666", blue: "#334466", purple: "#553366",
        specialWhite: "#e8e8e8", accent: ""
    })

    property color bg0: defaults.bg0
    property color bg1: defaults.bg1
    property color bg2: defaults.bg2
    property color bg3: defaults.bg3
    property color bg4: defaults.bg4
    property color fg1: defaults.fg1
    property color fg2: defaults.fg2
    property color surface: defaults.surface
    property color red: defaults.red
    property color orange: defaults.orange
    property color yellow: defaults.yellow
    property color green: defaults.green
    property color cyan: defaults.cyan
    property color aqua: defaults.aqua
    property color blue: defaults.blue
    property color purple: defaults.purple
    property color specialWhite: defaults.specialWhite
    property color accent: defaults.fg1

    // Fonts and sizes — set in the Settings app (Config.qml / config.json)
    readonly property string font: Config.appearance.font
    // Icons: Google's Material Symbols (Rounded), by name, e.g. text: "volume_up".
    // No Nerd Font anywhere: the Arch logo is an SVG (components/ArchLogo.qml).
    // Style picked in Settings → Appearance (Rounded / Outlined / Sharp); Rounded if it's not one of those
    readonly property string iconFont: Config.appearance.iconFont.startsWith("Material Symbols")
        && Qt.fontFamilies().includes(Config.appearance.iconFont) ? Config.appearance.iconFont : "Material Symbols Rounded"
    // Material 3 "fluid" icons: outlined at rest, filling in smoothly on hover / when active.
    // iconAxesWith(fill): fill 0–1 (animate it); "Always filled" in Settings forces 1.
    function iconAxesWith(fill) {
        return { "FILL": Config.icons.filled ? 1 : fill, "wght": Config.icons.weight, "GRAD": 0, "opsz": 24 };
    }
    readonly property var iconAxes: iconAxesWith(0)
    readonly property int fontSize: Config.appearance.fontSize
    readonly property int barHeight: Config.bar.height
    readonly property int barMargin: Config.bar.topMargin
    readonly property int barSideMargin: Config.bar.sideMargin
    readonly property int spacing: Config.bar.spacing
    readonly property int animMs: Math.round(300 * Config.appearance.animationSpeed)

    function parse(css) {
        const found = {};
        const re = /@define-color\s+([\w-]+)\s+(#[0-9a-fA-F]{3,8})/g;
        let m;
        while ((m = re.exec(css)) !== null) {
            const key = m[1].replace(/-(\w)/g, (_, c) => c.toUpperCase());
            found[key] = m[2];
        }
        for (const key in defaults) {
            if (key === "accent") continue;
            root[key] = found[key] ?? defaults[key];
        }
        // Some themes have no accent; fall back to blue like Waybar would look
        root.accent = found.accent ?? found.blue ?? root.fg1;
    }

    FileView {
        id: file
        path: root.themeFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }

    // ---------- Papirus folders in the accent color ----------
    // scripts/papirus-accent.sh builds the "Papirus-Accent" icon theme (Papirus-Dark with recolored
    // folders). Rerun whenever the accent changes; folderIcons / folderIconVersion let the shell
    // show the new folders right away (other apps pick them up when they next load icons).
    readonly property string folderIconDir: Quickshell.env("HOME") + "/.local/share/icons/Papirus-Accent"
    property int folderIconVersion: 0
    property var folderIcons: ({})          // names that exist in Papirus-Accent/64x64/places
    onAccentChanged: recolor.restart()
    Timer {
        id: recolor
        interval: 600                       // themes change several colors at once
        onTriggered: {
            const a = root.accent;
            const lum = 0.2126 * a.r + 0.7152 * a.g + 0.0722 * a.b;
            const hex = c => "#" + [c.r, c.g, c.b].map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("");
            folderRecolor.command = ["sh", Quickshell.shellDir + "/scripts/papirus-accent.sh",
                hex(a), hex(Qt.darker(a, 1.18)), hex(lum > 0.35 ? Qt.darker(a, 3.2) : Qt.lighter(a, 2.6))];
            folderRecolor.running = true;
        }
    }
    Process {
        id: folderRecolor
        onExited: code => { if (code === 0) folderList.running = true; }
    }
    Process {
        id: folderList
        running: true
        command: ["ls", root.folderIconDir + "/64x64/places"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = {};
                for (const f of text.split("\n")) if (f.endsWith(".svg")) names[f.slice(0, -4)] = true;
                root.folderIcons = names;
                root.folderIconVersion++;
            }
        }
    }

    // `qs ipc call theme reload` — called by the theme switcher
    IpcHandler {
        target: "theme"
        function reload(): void {
            file.reload();
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper-based colors (matugen). Same files as the old rofi menu:
// ~/.cache/dynamic-theme-enabled, ~/.cache/matugen-scheme, ~/.cache/matugen-mode
Singleton {
    id: root

    property bool enabled: false
    property string scheme: "scheme-tonal-spot"
    property string mode: "dark"

    readonly property var schemes: [
        ["scheme-tonal-spot", "Default"], ["scheme-vibrant", "Punchy"],
        ["scheme-expressive", "Colorful"], ["scheme-fidelity", "Close to the wallpaper"],
        ["scheme-content", "Content-aware"], ["scheme-neutral", "Muted"],
        ["scheme-monochrome", "Grayscale"], ["scheme-rainbow", "Multi-hue"],
        ["scheme-fruit-salad", "Playful"]
    ]

    // Regenerate colors from the wallpaper that's on screen now
    readonly property string applyCmd: `
        WALL=$(awww query | grep -o 'image: .*' | head -1); WALL=\${WALL#image: }
        [ -f "$WALL" ] && SKIP_WALLPAPER=1 ~/.config/hypr/scripts/wallpaper-dynamic.sh "$WALL"`

    function run(cmd, message) {
        Quickshell.execDetached(["sh", "-c", cmd + (message
            ? `; notify-send "Dynamic Theme" "${message}" --icon=preferences-desktop-theme --hint=int:transient:1` : "")]);
        refreshTimer.restart();
    }

    function setEnabled(on) {
        enabled = on;
        run(on ? "touch ~/.cache/dynamic-theme-enabled" : "rm -f ~/.cache/dynamic-theme-enabled",
            on ? "Enabled — pick a wallpaper to apply" : "Disabled");
    }

    function applyNow() {
        if (!enabled) { run("true", "Enable dynamic theme first"); return; }
        run(applyCmd, "");
    }

    function setScheme(id) {
        scheme = id;
        run(`echo ${id} > ~/.cache/matugen-scheme; [ -f ~/.cache/dynamic-theme-enabled ] && { ${applyCmd}; }`, "Scheme: " + id);
    }

    function setMode(m) {
        mode = m;
        run(`echo ${m} > ~/.cache/matugen-mode; [ -f ~/.cache/dynamic-theme-enabled ] && { ${applyCmd}; }`, "Mode: " + m);
    }

    function refresh() { stateProc.running = true; }

    Timer { id: refreshTimer; interval: 400; onTriggered: root.refresh() }

    Process {
        id: stateProc
        running: true
        command: ["sh", "-c", `
            [ -f ~/.cache/dynamic-theme-enabled ] && echo on || echo off
            tr -d '[:space:]' < ~/.cache/matugen-scheme 2>/dev/null; echo
            tr -d '[:space:]' < ~/.cache/matugen-mode 2>/dev/null; echo`]
        stdout: StdioCollector {
            onStreamFinished: {
                const [on, scheme, mode] = text.split("\n");
                root.enabled = on === "on";
                root.scheme = scheme || "scheme-tonal-spot";
                root.mode = mode || "dark";
            }
        }
    }
}

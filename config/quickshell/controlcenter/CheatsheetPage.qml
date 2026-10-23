import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Keyboard shortcuts — generated from binds.lua at ~/.cache/quickshell-binds.json
// scripts/gen-binds-json.py parses ~/.config/hypr/modules/binds.lua and rewrites the
// cache; we rerun it whenever binds.lua changes (and once on load). If generation
// fails the hand-written fallbackItems below keep the page populated.
MenuList {
    id: root

    property var cc   // set by the loader

    placeholder: "Search shortcuts…"
    rowHeight: 44

    readonly property string bindsPath: Quickshell.env("HOME") + "/.config/hypr/modules/binds.lua"
    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/quickshell-binds.json"

    property var entries: []          // [{ combo, description, group }] from the cache

    // Used only when the generator or the cache is unavailable
    property var fallbackItems: [
        ["terminal", "SUPER + T", "Terminal"],
        ["cancel", "SUPER + Q", "Close window"],
        ["language", "SUPER + B", "Browser"],
        ["code", "SUPER + C", "VS Code"],
        ["folder", "SUPER + E", "Files"],
        ["forum", "SUPER + D", "Discord"],
        ["music_note", "SUPER + M", "Spotify"],
        ["apps", "SUPER + SPACE", "App launcher"],
        ["tune", "SUPER + X", "Quick settings"],
        ["dashboard", "SUPER + A", "Dashboard"],
        ["notifications", "SUPER + N", "Notifications"],
        ["view_carousel", "SUPER + TAB", "Workspace overview"],
        ["settings_applications", "SUPER + COMMA", "Settings"],
        ["power_settings_new", "SUPER + P", "Power menu"],
        ["lock", "SUPER + SHIFT + L", "Lock screen"],
        ["picture_in_picture", "SUPER + W", "Toggle floating"],
        ["monitor", "SUPER + F", "Maximize"],
        ["fullscreen", "SUPER + SHIFT + F", "Fullscreen"],
        ["select_window", "SUPER + S", "Scratchpad"],
        ["restart_alt", "SUPER + R", "Restart Quickshell"],
        ["settings", "SUPER + ALT + SPACE", "Control center"],
        ["palette", "SUPER + SHIFT + T", "Theme switcher"],
        ["wallpaper", "SUPER + SHIFT + W", "Wallpaper picker"],
        ["content_paste", "SUPER + SHIFT + C", "Clipboard"],
        ["photo_camera", "SUPER + SHIFT + V", "Capture menu"],
        ["screenshot_monitor", "SUPER + SHIFT + S", "Screenshot region"],
        ["colorize", "SUPER + SHIFT + P", "Color picker"],
        ["mood", "SUPER + PERIOD", "Emoji"],
        ["skip_next", "SUPER + J/L/I/K", "Move focus"],
        ["skip_next", "SUPER + 1-0", "Switch workspace"],
        ["skip_next", "SUPER + SHIFT + 1-0", "Move window to workspace"],
        ["mouse", "SUPER + scroll", "Cycle workspaces"]
    ].map(([icon, keys, what]) => ({ icon, label: what, sub: keys }))

    // Icon chosen by keyword, in priority order (first match wins)
    readonly property var iconRules: [
        ["lmb drag", "open_with"],
        ["rmb drag", "aspect_ratio"],
        ["scroll", "mouse"],
        ["close window", "cancel"],
        ["terminal", "terminal"],
        ["kitty", "terminal"],
        ["browser", "language"],
        ["chrome", "language"],
        ["vs code", "code"],
        ["vscode", "code"],
        ["dolphin", "folder"],
        ["file manager", "folder"],
        ["files", "folder"],
        ["spotify", "music_note"],
        ["discord", "forum"],
        ["launcher", "apps"],
        ["dashboard", "dashboard"],
        ["overview", "view_carousel"],
        ["notification", "notifications"],
        ["screenshot", "screenshot_monitor"],
        ["capture", "photo_camera"],
        ["wallpaper", "wallpaper"],
        ["theme", "palette"],
        ["clipboard", "content_paste"],
        ["emoji", "mood"],
        ["quick settings", "tune"],
        ["settings", "settings_applications"],
        ["power", "power_settings_new"],
        ["lock", "lock"],
        ["brightness", "brightness_6"],
        ["volume up", "volume_up"],
        ["volume down", "volume_down"],
        ["mute output", "volume_off"],
        ["mute microphone", "mic_off"],
        ["next track", "skip_next"],
        ["previous track", "skip_previous"],
        ["play / pause", "play_arrow"],
        ["move focus", "open_with"],
        ["special workspace", "select_window"],
        ["workspace", "view_agenda"],
        ["control center", "settings"],
        ["restart", "restart_alt"],
        ["maximize", "monitor"],
        ["fullscreen", "fullscreen"],
        ["floating", "picture_in_picture"],
        ["color picker", "colorize"]
    ]

    function iconFor(entry) {
        const haystack = ((entry.combo ?? "") + " " + (entry.description ?? "") + " " + (entry.group ?? "")).toLowerCase();
        for (let i = 0; i < iconRules.length; i++) {
            const rule = iconRules[i];
            if (haystack.includes(rule[0])) return rule[1];
        }
        return "keyboard";
    }

    items: root.entries.length > 0
        ? root.entries.map(e => ({
            icon: root.iconFor(e),
            label: e.description,
            sub: e.combo,
            keywords: e.group ?? ""
        }))
        : root.fallbackItems

    function refresh() {
        if (!gen.running) gen.running = true;
    }

    Component.onCompleted: refresh()

    // Regenerate the JSON, then read it back (only on success — otherwise keep what we have)
    Process {
        id: gen
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/gen-binds-json.py", root.bindsPath]
        onExited: code => {
            if (code === 0) reader.running = true;
        }
    }

    Process {
        id: reader
        command: ["cat", root.cachePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (Array.isArray(data) && data.length > 0) root.entries = data;
                } catch (e) {
                    // Malformed cache: leave entries alone so the fallback stays visible
                }
            }
        }
    }

    // Hot reload on save
    FileView {
        id: bindsWatch
        path: root.bindsPath
        watchChanges: true
        onFileChanged: {
            reload();
            regen.restart();
        }
    }

    Timer {
        id: regen
        interval: 300
        onTriggered: root.refresh()
    }

    onBack: cc?.go("main")
}

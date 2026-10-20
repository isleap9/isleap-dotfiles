pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which bar is shown, and what's on it.
//   default, default2, minimal, sleek — the layouts imported from Waybar (fixed, not editable)
//   custom — your own bar, built in Settings → Bar (its lanes/style/position live in Config.bar)
Singleton {
    id: root

    readonly property var waybarLayouts: ["default", "default2", "minimal", "sleek"]
    readonly property var layouts: [...waybarLayouts, "custom"]
    readonly property var laneNames: ["left", "center", "right"]

    // The bar being shown
    readonly property string layout: layouts.includes(Config.bar.preset) ? Config.bar.preset : "default"
    readonly property bool isCustom: layout === "custom"
    readonly property var preset: presetData(isCustom ? "default" : layout)

    // What the bar draws: the Custom bar's own settings, or the fixed Waybar layout
    readonly property var lanes: isCustom ? (Config.bar.lanes ?? {}) : preset.lanes
    readonly property var grouped: isCustom ? (Config.bar.grouped ?? {}) : preset.grouped
    readonly property bool solid: (isCustom ? Config.bar.style : preset.style) === "solid"
    readonly property bool bottom: isCustom && Config.bar.position === "bottom"
    readonly property bool customSolid: Config.bar.style === "solid"

    // ── Look (Settings → Bar → Look). Waybar layouts always use the defaults. ──
    // Colors are theme color names (accent, fg1, bg2, red…) so they follow the theme switcher,
    // or "#rrggbb". "" = automatic.
    readonly property var lookDefaults: ({
        background: "",        // pills: bg1, solid bar: bg0
        opacity: 100,          // background opacity, %
        borderWidth: 0,
        borderColor: "accent",
        roundness: 100,        // pills: % of fully round
        barRadius: 10,         // solid bar corner radius, px
        density: "default",    // compact, default, comfortable
        textColor: "fg1",
        iconColor: "fg1",
        accentColor: "accent", // active workspace
        textSize: 0,           // 0 = the app font size (Settings → Appearance)
        iconSize: 0,           // 0 = text size + 3
        textWeight: "black",   // regular, bold, black
        solidGap: 0,           // solid bar: gap from the screen edge, px
        solidWidth: "fit",     // solid bar: fit (around the widgets) or full (screen width)
        outerCorners: false    // solid bar touching the edge: curved corners blending into it
    })
    readonly property var customLook: Config.bar.look ?? {}
    function look(key) {
        const v = isCustom ? customLook[key] : undefined;
        return v !== undefined && v !== null ? v : lookDefaults[key];
    }
    function setLook(key, value) {
        const l = Object.assign({}, customLook);
        l[key] = value;
        Config.bar.look = l;
    }
    function resetLook() { Config.bar.look = {}; }

    // Custom bar style as shown in Settings: pills, floatingBar (one bar with a gap) or attached
    readonly property string customStyle: Config.bar.style !== "solid" ? "pills"
        : (customLook.solidGap ?? 0) > 0 ? "floatingBar" : "attached"
    function setCustomStyle(s) {
        if (s === "pills") { Config.bar.style = "floating"; return; }
        Config.bar.style = "solid";
        if (s === "attached") setLook("solidGap", 0);
        else if ((customLook.solidGap ?? 0) === 0) setLook("solidGap", Math.max(4, Config.bar.topMargin));
    }

    // Theme color name or hex → color ("" or unknown → fallback)
    function color(name, fallback) {
        if (!name) return fallback;
        if (String(name).startsWith("#")) return name;
        return Theme[name] ?? fallback;
    }
    function withOpacity(c, percent) { return Qt.rgba(c.r, c.g, c.b, c.a * percent / 100); }

    readonly property string density: look("density")
    readonly property int pillPadding: ({ compact: 11, comfortable: 26 })[density] ?? 18
    readonly property int sharedPadding: ({ compact: 10, comfortable: 22 })[density] ?? 16
    readonly property int solidSpacing: ({ compact: 2, comfortable: 10 })[density] ?? 4
    // Padding for widgets without their own pill (inside a shared pill, or on the solid bar)
    readonly property int flatPadding: solid ? (({ compact: 3, comfortable: 9 })[density] ?? 5) : 0

    readonly property int bgOpacity: look("opacity")
    readonly property color pillColor: withOpacity(color(look("background"), Theme.bg1), bgOpacity)
    readonly property color solidColor: withOpacity(color(look("background"), Theme.bg0), bgOpacity)
    readonly property int borderWidth: look("borderWidth")
    readonly property color borderColor: color(look("borderColor"), Theme.accent)
    readonly property real roundness: look("roundness") / 100
    readonly property int barRadius: look("barRadius")
    readonly property color textColor: color(look("textColor"), Theme.fg1)
    readonly property color iconColor: color(look("iconColor"), Theme.fg1)
    readonly property color accentColor: color(look("accentColor"), Theme.accent)
    readonly property int textSize: look("textSize") > 0 ? look("textSize") : Theme.fontSize
    readonly property int iconSize: look("iconSize") > 0 ? look("iconSize") : textSize + 3
    readonly property int textWeight: ({ regular: Font.Normal, bold: Font.Bold })[look("textWeight")] ?? Font.Black
    readonly property int solidGap: solid ? look("solidGap") : 0
    readonly property bool solidFull: solid && look("solidWidth") === "full"
    readonly property bool outerCorners: solid && solidGap === 0 && look("outerCorners") === true

    // ── Widget catalog ──────────────────────────────────────────────────────
    // options: what the ⚙ button in Settings shows for that widget
    //   { key, label, type: "toggle" | "choice" | "number", choices: [[value, label]], from, to, step, default }
    readonly property var catalog: ({
        arch: { name: "App launcher", icon: "󰣇", desc: "Arch logo — click: apps, right-click: control center", options: [] },
        weather: { name: "Weather", icon: "󰖐", desc: "Temperature; click: forecast, hover: summary", options: [] },
        clock: { name: "Clock", icon: "󰥔", desc: "Time; click: dashboard, right-click: full date, hover: calendar", options: [
            { key: "format", label: "Shows", type: "choice", default: "auto", choices: [
                ["auto", "Time"], ["date", "Date + time"], ["hour", "Hour only"], ["minutes", "Minutes only"]] },
            { key: "calendar", label: "Calendar on hover", type: "toggle", default: true },
            { key: "large", label: "Big text", type: "toggle", default: false }] },
        cava: { name: "Audio visualizer", icon: "󰎈", desc: "Bars that move with your music (cava)", options: [] },
        media: { name: "Now playing", icon: "󰝚", desc: "Cover, song and buttons; click: dashboard, scroll: skip", options: [
            { key: "maxWidth", label: "Max title width", type: "number", from: 80, to: 600, step: 20, suffix: " px", default: 220 },
            { key: "cover", label: "Album cover", type: "toggle", default: true },
            { key: "artist", label: "Artist on a second line", type: "toggle", default: true },
            { key: "progress", label: "Progress line", type: "toggle", default: true },
            { key: "controls", label: "Previous / play / next buttons", type: "toggle", default: true }] },
        workspaces: { name: "Workspaces", icon: "󰍹", desc: "Click to switch, scroll to cycle", options: [
            { key: "style", label: "Style", type: "choice", default: "default", choices: [
                ["default", "Pills"], ["classic", "Classic"], ["sleek", "Dots"]] },
            { key: "activeColor", label: "Active workspace color", type: "color", default: "" }] },
        tray: { name: "System tray", icon: "󰀻", desc: "App icons (Discord, Steam…)", options: [] },
        language: { name: "Keyboard layout", icon: "󰌌", desc: "UK / IT", options: [
            { key: "label", label: "Show text", type: "toggle", default: true }] },
        volume: { name: "Volume", icon: "󰕾", desc: "Click: mixer, right-click: mute, scroll: volume", options: [
            { key: "label", label: "Show percentage", type: "toggle", default: true }] },
        network: { name: "Network", icon: "󰈀", desc: "Ethernet / Wi-Fi; click to open nmtui", options: [
            { key: "label", label: "Show Wi-Fi name", type: "toggle", default: true }] },
        notifications: { name: "Notifications", icon: "󰂚", desc: "Click: notification center, right-click: do not disturb", options: [] },
        power: { name: "Power menu", icon: "󰐥", desc: "Lock, suspend, logout, reboot, shutdown", options: [] },
        controlcenter: { name: "Control center", icon: "󰒓", desc: "Opens the control center", options: [] },
        settings: { name: "Settings", icon: "󰒓", desc: "Opens this Settings app", options: [] },
        screenshot: { name: "Screenshot", icon: "󰹑", desc: "Click: region, right-click: capture menu", options: [] },
        spacer: { name: "Spacer", icon: "󰇘", desc: "Empty space", options: [
            { key: "width", label: "Width", type: "number", from: 4, to: 200, step: 4, suffix: " px", default: 24 }] }
    })
    readonly property var catalogOrder: ["arch", "workspaces", "clock", "weather", "media", "cava", "tray",
        "language", "volume", "network", "notifications", "power", "controlcenter", "settings", "screenshot", "spacer"]

    // Look options every widget gets under ⚙ ("" = use the bar's Look setting)
    readonly property var commonOptions: [
        { key: "textColor", label: "Text color", type: "color", default: "" },
        { key: "iconColor", label: "Icon color", type: "color", default: "" },
        { key: "background", label: "Background", type: "color", default: "", pillOnly: true }
    ]
    function optionsFor(type) {
        if (type === "spacer") return catalog.spacer.options;
        const own = catalog[type]?.options ?? [];
        // cava and workspaces draw shapes, not text: only the background applies
        let common = commonOptions;
        if (type === "workspaces" || type === "tray") common = commonOptions.filter(o => o.key === "background");
        if (type === "cava") common = [Object.assign({}, commonOptions[0], { label: "Bars color" }), commonOptions[2]];
        return [...own, ...common];
    }

    // A widget's option, falling back to the catalog default
    function opt(widget, key) {
        if (widget && widget[key] !== undefined) return widget[key];
        const o = optionsFor(widget?.type).find(o => o.key === key);
        return o ? o.default : undefined;
    }

    // ── Presets (the old Waybar layouts) ────────────────────────────────────
    function w(type, extra) { return Object.assign({ type }, extra ?? {}); }
    function presetData(name) {
        const right = [w("tray"), w("language"), w("volume"), w("network"), w("notifications"), w("power")];
        switch (name) {
        case "default2": return {
            style: "floating",
            lanes: { left: [w("arch"), w("weather"), w("clock"), w("media")],
                     center: [w("workspaces", { style: "classic" })], right },
            grouped: { left: false, center: false, right: true } };
        case "minimal": return {
            style: "floating",
            lanes: { left: [], right: [],
                     center: [w("arch"), w("weather"), w("clock"), w("workspaces", { style: "classic" }), w("media"), ...right] },
            grouped: { left: false, center: true, right: false } };
        case "sleek": return {
            style: "solid",
            lanes: { left: [w("arch"), w("volume"), w("cava"), w("media", { maxWidth: 240 })],
                     center: [w("clock", { format: "hour", calendar: true, large: true }), w("workspaces", { style: "sleek" }),
                              w("clock", { format: "minutes", calendar: false, large: true }), w("weather")],
                     right: [w("tray"), w("language"), w("network"), w("notifications"), w("power")] },
            grouped: { left: false, center: false, right: false } };
        default: return {
            style: "floating",
            lanes: { left: [w("arch"), w("weather"), w("clock"), w("cava"), w("media")],
                     center: [w("workspaces")], right },
            grouped: { left: false, center: false, right: false } };
        }
    }

    // Show a bar (doesn't change any bar's contents)
    function set(name) {
        if (!layouts.includes(name)) return;
        Config.bar.preset = name;
    }

    // Replace the Custom bar with a copy of a Waybar layout
    function resetCustom(from) {
        const p = presetData(from);
        Config.bar.lanes = p.lanes;
        Config.bar.grouped = p.grouped;
        Config.bar.style = p.style;
        Config.bar.position = "top";
    }

    // ── Editing (used by Settings → Bar) ────────────────────────────────────
    function copyLanes() { return JSON.parse(JSON.stringify(Config.bar.lanes)); }
    function commit(lanes) { Config.bar.lanes = lanes; }

    function add(lane, type) {
        const l = copyLanes();
        l[lane] = [...(l[lane] ?? []), { type }];
        commit(l);
    }
    function remove(lane, index) {
        const l = copyLanes();
        l[lane].splice(index, 1);
        commit(l);
    }
    function move(lane, index, delta) {
        const l = copyLanes();
        const to = index + delta;
        if (to < 0 || to >= l[lane].length) return;
        [l[lane][index], l[lane][to]] = [l[lane][to], l[lane][index]];
        commit(l);
    }
    function moveToLane(lane, index, toLane) {
        const l = copyLanes();
        const [item] = l[lane].splice(index, 1);
        l[toLane] = [...(l[toLane] ?? []), item];
        commit(l);
    }
    function setOption(lane, index, key, value) {
        const l = copyLanes();
        l[lane][index][key] = value;
        commit(l);
    }
    function setGrouped(lane, on) {
        const g = Object.assign({}, Config.bar.grouped);
        g[lane] = on;
        Config.bar.grouped = g;
    }

    // First run with this version: start from the layout picked before (old Waybar file)
    FileView {
        id: oldLayout
        path: Quickshell.env("HOME") + "/.config/waybar/current-layout"
        blockLoading: true
    }
    Timer {
        // Wait until config.json has been read
        interval: 500
        running: true
        onTriggered: {
            if (Config.bar.customVersion < 1) {
                root.resetCustom("default");
                Config.bar.customVersion = 1;
            }
            if (!root.layouts.includes(Config.bar.preset)) {
                const name = (oldLayout.text() ?? "").trim();
                root.set(root.waybarLayouts.includes(name) ? name : "default");
            }
        }
    }

    // qs ipc call bar layout sleek
    IpcHandler {
        target: "bar"
        function layout(name: string): void { root.set(name); }
        function next(): void {
            const i = root.layouts.indexOf(root.layout);
            root.set(root.layouts[(i + 1) % root.layouts.length]);
        }
    }
}

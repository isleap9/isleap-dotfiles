import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import qs.components

// App launcher (SUPER+A). Type to search, ↑/↓ to pick, Enter to launch, Esc to close.
LazyLoader {
    id: loader

    // Open/close animation (Settings → Animations)
    property PanelMotion motion: PanelMotion { style: Config.animations.launcher; open: Globals.launcherOpen }
    active: motion.needed

    PanelWindow {
        id: win

        screen: Globals.popupScreen
        // No anchors = centered on screen
        // Extra room around the card so animations aren't cut off; only the card takes clicks
        readonly property int pad: 60
        implicitWidth: Config.launcher.width + pad * 2
        readonly property int heroH: Config.launcher.hero ? Config.launcher.heroHeight + 12 : 0
        implicitHeight: Config.launcher.height + heroH + pad * 2
        mask: Region { item: hitBox }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Globals.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-launcher"

        // ── Usage store: launch counts, used only to order app rows ──
        // ~/.cache/launch-counts.json → {"<app name>": {"count": 3, "ts": 1700000000}}
        readonly property string usagePath: Quickshell.env("HOME") + "/.cache/launch-counts.json"
        // Adapter-backed map, same shape as the file (alias mirrors Config.qml's pattern)
        property alias usage: usageAdapter.usage
        // Snapshot read once per open, so ranking never changes under the user mid-session
        property var usageMap: ({})

        FileView {
            id: usageFile
            path: win.usagePath
            onAdapterUpdated: usageSave.restart()
            onLoaded: win.usageMap = win.readUsage()
            onLoadFailed: error => {
                if (error === FileViewError.FileNotFound) writeAdapter();
            }

            JsonAdapter {
                id: usageAdapter
                property var usage: ({})
            }
        }
        Timer { id: usageSave; interval: 150; onTriggered: usageFile.writeAdapter() }

        // File contents → plain JS map with defensive numbers
        function readUsage() {
            const out = {};
            const src = win.usage;
            if (!src) return out;
            for (const k in src) {
                const rec = src[k];
                if (!rec) continue;
                out[k] = { count: Number(rec["count"]) || 0, ts: Number(rec["ts"]) || 0 };
            }
            return out;
        }

        // Missing record → 0 (and never a NaN from a hand-edited file)
        function usageCount(name) {
            const rec = win.usageMap ? win.usageMap[name] : null;
            return rec ? (Number(rec["count"]) || 0) : 0;
        }
        function usageTs(name) {
            const rec = win.usageMap ? win.usageMap[name] : null;
            return rec ? (Number(rec["ts"]) || 0) : 0;
        }

        // count + 1 and now, as a fresh object so the adapter notices and saves
        function bumpUsage(name) {
            if (!name) return;
            // Fall back to the adapter if the snapshot was read before the file loaded
            const cur = (win.usageMap && Object.keys(win.usageMap).length) ? win.usageMap : win.readUsage();
            const prev = cur[name];
            const next = {};
            for (const k in cur) next[k] = cur[k];
            next[name] = {
                count: (prev ? (Number(prev["count"]) || 0) : 0) + 1,
                ts: Math.round(Date.now() / 1000)
            };
            win.usageMap = next;
            win.usage = next;
            // The launcher closes right after a launch, so don't leave it to the debounce
            usageSave.stop();
            usageFile.writeAdapter();
        }

        Component.onCompleted: win.usageMap = win.readUsage()

        // ── Results ──
        // Every row is a plain object: { kind: "app" | "calc" | "web" | "file", ... }
        readonly property var appRows: {
            const q = search.text.trim().toLowerCase();
            const all = DesktopEntries.applications.values.filter(a => !a.noDisplay);
            if (q === "")
                return all.slice().sort((a, b) =>
                    win.usageCount(b.name) - win.usageCount(a.name)
                    || win.usageTs(b.name) - win.usageTs(a.name)
                    || a.name.localeCompare(b.name)
                ).map(a => ({ kind: "app", app: a }));

            // Score: name starts with > word in name starts with > name contains > other fields contain
            const score = a => {
                const name = a.name.toLowerCase();
                if (name.startsWith(q)) return 0;
                if (name.split(/\s+/).some(w => w.startsWith(q))) return 1;
                if (name.includes(q)) return 2;
                const extra = [a.genericName, a.comment, (a.keywords ?? []).join(" "), a.id]
                    .join(" ").toLowerCase();
                return extra.includes(q) ? 3 : -1;
            };
            return all.map(a => ({ a, s: score(a) }))
                .filter(x => x.s >= 0)
                .sort((x, y) =>
                    x.s - y.s
                    || win.usageCount(y.a.name) - win.usageCount(x.a.name)
                    || win.usageTs(y.a.name) - win.usageTs(x.a.name)
                    || x.a.name.localeCompare(y.a.name))
                .map(x => ({ kind: "app", app: x.a }));
        }

        // Arithmetic query → { expr, value }; null when the text isn't a sum.
        // Accept only if the whole string is digits/operators/parens, has a digit and an operator,
        // and the parser can read it (a lone number isn't worth a row).
        readonly property var calcRow: {
            const raw = search.text.trim();
            if (!/^[0-9+\-*\/%^().\s]+$/.test(raw)) return null;
            if (!/[0-9]/.test(raw) || !/[+\-*\/%^]/.test(raw)) return null;
            try {
                const n = win.parseArithmetic(raw);
                if (!isFinite(n)) return null;
                return { kind: "calc", expr: raw, value: win.formatNumber(n) };
            } catch (e) {
                return null;   // malformed: "1..2", "(1+2", "5%", "1 2"…
            }
        }

        // calc (when it parses) → apps → web search → files
        readonly property var results: {
            const rows = [];
            if (win.calcRow) rows.push(win.calcRow);
            rows.push(...win.appRows);
            const q = search.text.trim();
            if (q !== "" && Config.launcher.webSearch) rows.push({ kind: "web", q });
            if (Config.launcher.fileSearch && win.fileResults.length) rows.push(...win.fileResults);
            return rows;
        }

        // ── Calculator: recursive-descent parser (no eval / Function constructor; hoisted declarations) ──
        // expr    := term (('+'|'-') term)*
        // term    := unary (('*'|'/'|'%') unary)*
        // unary   := '-' unary | power
        // power   := primary ('^' unary)?        ^ is right-associative
        // primary := number | '(' expr ')'
        function parseArithmetic(src) {
            let i = 0;
            function fail() { throw new Error("bad expression"); }
            function skip() { while (i < src.length && /\s/.test(src.charAt(i))) i++; }
            function number() {
                skip();
                const m = /^(?:\d+(?:\.\d*)?|\.\d+)/.exec(src.slice(i));
                if (!m) fail();
                i += m[0].length;
                return parseFloat(m[0]);
            }
            function primary() {
                skip();
                if (src.charAt(i) === "(") {
                    i++;
                    const v = expr();
                    skip();
                    if (src.charAt(i) !== ")") fail();
                    i++;
                    return v;
                }
                return number();
            }
            function power() {
                const base = primary();
                skip();
                if (src.charAt(i) === "^") { i++; return Math.pow(base, unary()); }
                return base;
            }
            function unary() {
                skip();
                if (src.charAt(i) === "-") { i++; return -unary(); }
                return power();
            }
            function term() {
                let v = unary();
                for (;;) {
                    skip();
                    const c = src.charAt(i);
                    if (c !== "*" && c !== "/" && c !== "%") return v;
                    i++;
                    const r = unary();
                    v = c === "*" ? v * r : c === "/" ? v / r : v % r;
                }
            }
            function expr() {
                let v = term();
                for (;;) {
                    skip();
                    const c = src.charAt(i);
                    if (c !== "+" && c !== "-") return v;
                    i++;
                    const r = term();
                    v = c === "+" ? v + r : v - r;
                }
            }
            const v = expr();
            skip();
            if (i !== src.length) fail();   // trailing junk, e.g. "1 2"
            return v;
        }

        // 46, 0.5, 3.141593 — up to 6 decimals, trailing zeros trimmed
        function formatNumber(n) {
            const s = n.toFixed(6).replace(/\.?0+$/, "");
            return s === "-0" || s === "" ? "0" : s;
        }

        function baseName(p) {
            return p.substring(p.lastIndexOf("/") + 1) || p;
        }
        function dirName(p) {
            const i = p.lastIndexOf("/");
            return i <= 0 ? "/" : p.slice(0, i);
        }

        // ── File search: debounced `find` over $HOME, at most 8 matches ──
        property var fileResults: []

        function startFind() {
            const q = search.text.trim();
            if (!Config.launcher.fileSearch || q.length < 3) {
                findProc.running = false;
                win.fileResults = [];
                return;
            }
            // find glob: letters, digits, underscore, dot, space and dash only (no quotes reach the shell)
            const safe = q.replace(/[^a-zA-Z0-9_. -]/g, "");
            if (safe === "") { win.fileResults = []; return; }
            if (findProc.running) {              // let the old find stop before starting another
                findProc.running = false;
                findDebounce.restart();
                return;
            }
            const pattern = "*" + safe + "*";
            findProc.forQuery = q;
            findProc.command = ["sh", "-c",
                "find \"$HOME\" -maxdepth 4 \\( -path '*/.*' -prune \\) -o -type f -iname '"
                + pattern + "' -printf 'f %p\\n' -o -type d -iname '" + pattern
                + "' -printf 'd %p\\n' 2>/dev/null | head -8"];
            findProc.running = true;
        }

        Timer {
            id: findDebounce
            interval: 250
            onTriggered: win.startFind()
        }

        Process {
            id: findProc
            property string forQuery: ""
            stdout: StdioCollector {
                onStreamFinished: {
                    // Drop results that arrived after the query moved on
                    if (!Config.launcher.fileSearch || findProc.forQuery !== search.text.trim()) return;
                    const rows = [];
                    for (const line of text.split("\n")) {
                        const t = line.charAt(0);          // "f" file, "d" directory
                        if ((t !== "f" && t !== "d") || line.charAt(1) !== " ") continue;
                        const path = line.slice(2);
                        if (!path || path.indexOf('"') >= 0 || path.indexOf("\n") >= 0) continue;
                        rows.push({ kind: "file", path, isDir: t === "d" });
                    }
                    win.fileResults = rows;
                }
            }
        }

        // Run the row's action, then close
        function activate(row) {
            if (!row) return;
            if (row.kind === "app") {
                // Only app launches feed the ranking store
                if (row.app && row.app.name) win.bumpUsage(row.app.name);
                row.app.execute();
            }
            else if (row.kind === "calc") Quickshell.execDetached(["wl-copy", String(row.value)]);
            else if (row.kind === "web") Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(row.q)]);
            else if (row.kind === "file") Quickshell.execDetached(["xdg-open", row.path]);
            else return;
            Globals.launcherOpen = false;
        }

        // Current wallpaper on this monitor (for the banner)
        property string wall: ""
        Process {
            running: Config.launcher.hero
            command: ["sh", "-c", "awww query 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let first = "";
                    for (const line of text.split("\n")) {
                        const r = line.match(/^:?\s*([^:]+):.*image: (.+)$/);
                        if (!r) continue;
                        if (!first) first = r[2].trim();
                        if (r[1].trim() === (win.screen ? win.screen.name : "")) { win.wall = r[2].trim(); return; }
                    }
                    win.wall = first;
                }
            }
        }
        SystemClock { id: clock; precision: SystemClock.Minutes }
        readonly property string greeting: {
            const h = clock.date.getHours();
            return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
        }

        HyprlandFocusGrab {
            active: Globals.launcherOpen
            windows: [win]
            onCleared: Globals.launcherOpen = false
        }

        // What takes clicks: the card's resting place. Not the card itself, which zooms in on
        // open; the click area was measured mid-zoom, so clicks near the card's edges (like
        // on the scrollbar) counted as "outside" and closed the panel.
        Item {
            id: hitBox
            anchors.fill: parent
            anchors.margins: win.pad
        }

        Rectangle {
            id: card
            anchors.fill: parent
            anchors.margins: win.pad
            opacity: loader.motion.opacityValue
            scale: loader.motion.scaleValue
            transform: Translate { y: loader.motion.offset }
            radius: 28
            // Same color and transparency as the bar (Settings → Bar)
            color: BarConfig.solidColor
            border.width: BarConfig.borderWidth > 0 ? BarConfig.borderWidth : 1
            border.color: BarConfig.borderWidth > 0 ? BarConfig.borderColor : Qt.rgba(Theme.fg1.r, Theme.fg1.g, Theme.fg1.b, 0.08)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // ── Hero: current wallpaper with the time and a greeting ──
                ClippingRectangle {
                    visible: Config.launcher.hero
                    Layout.fillWidth: true
                    Layout.preferredHeight: Config.launcher.heroHeight
                    radius: 20
                    color: Theme.bg1

                    Image {
                        id: wallImg
                        anchors.fill: parent
                        source: win.wall ? "file://" + win.wall : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 1280
                        opacity: status === Image.Ready ? 1 : 0
                        scale: status === Image.Ready ? 1 : 1.06
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                    // Darken the bottom so the text stays readable on any wallpaper
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.05) }
                            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.15) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                        }
                    }

                    ColumnLayout {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 18 }
                        spacing: 0
                        Text {
                            text: Config.bar.clock24h ? Qt.formatDateTime(clock.date, "HH:mm")
                                : Qt.formatDateTime(clock.date, "hh:mm AP").split(" ")[0]
                            color: "white"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 26
                            font.weight: Font.Bold
                            font.features: ({ tnum: 1 })
                        }
                        Text {
                            text: `${win.greeting}, ${Quickshell.env("USER")}`
                            color: Qt.rgba(1, 1, 1, 0.85)
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.Medium
                        }
                    }

                    // App count chip
                    Rectangle {
                        anchors { right: parent.right; top: parent.top; margins: 12 }
                        implicitHeight: 28
                        implicitWidth: chip.implicitWidth + 20
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.35)
                        Text {
                            id: chip
                            anchors.centerIn: parent
                            text: win.appRows.length + (win.appRows.length === 1 ? " app" : " apps")
                            color: "white"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.Medium
                        }
                    }
                }

                // ── Search field: accent outline and icon while focused, clear button ──
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 26
                    color: BarConfig.surface(Theme.bg1)
                    border.width: search.activeFocus ? 2 : 0
                    border.color: Theme.accent
                    Behavior on border.width { NumberAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 10
                        spacing: 12

                        Text {
                            text: "search"
                            color: search.activeFocus ? Theme.accent : Theme.fg2
                            Behavior on color { ColorAnimation { duration: 150 } }
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: Theme.fontSize + 6
                        }

                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            focus: true
                            color: Theme.fg1
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.bg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 3
                            font.weight: Font.Medium
                            onTextChanged: {
                                list.currentIndex = 0;
                                win.fileResults = [];      // no stale file rows while the new search runs
                                if (Config.launcher.fileSearch) findDebounce.restart();
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: "Search apps…"
                                color: Theme.fg2
                                font: search.font
                            }

                            Keys.onEscapePressed: search.text !== "" ? search.text = "" : Globals.launcherOpen = false
                            Keys.onReturnPressed: win.activate(win.results[list.currentIndex])
                            Keys.onEnterPressed: win.activate(win.results[list.currentIndex])
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onTabPressed: list.incrementCurrentIndex()
                        }

                        MIconButton {
                            icon: "close"
                            size: 34
                            opacity: search.text !== "" ? 1 : 0
                            scale: search.text !== "" ? 1 : 0.6
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            onClicked: { search.text = ""; search.forceActiveFocus(); }
                        }
                    }
                }

                ListView {
                    SmoothWheel { flick: list }
                    MScrollBar { flick: list }
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: win.results
                    keyNavigationWraps: true
                    boundsBehavior: Flickable.StopAtBounds

                    // Selection pill glides between rows (Material emphasized easing)
                    highlightFollowsCurrentItem: false
                    highlight: Rectangle {
                        width: list.width - (list.contentHeight > list.height ? 12 : 0)
                        height: 56
                        y: list.currentItem ? list.currentItem.y : 0
                        radius: 18
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                        visible: list.count > 0
                        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
                    }

                    // Rows flow in, slightly staggered, on open and as you type
                    populate: Transition {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.max(0, Math.min(ViewTransition.index, 10)) * 14 }
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                                NumberAnimation { property: "y"; from: ViewTransition.destination.y + 14; duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel }
                            }
                        }
                    }

                    delegate: Item {
                        id: entry
                        required property var modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem
                        readonly property bool isApp: modelData.kind === "app"
                        readonly property string title: {
                            const d = entry.modelData;
                            if (d.kind === "app") return d.app.name;
                            if (d.kind === "calc") return d.expr + " = " + d.value;
                            if (d.kind === "web") return "Search the web for '" + d.q + "'";
                            if (d.kind === "file") return win.baseName(d.path);
                            return "";
                        }
                        readonly property string subtitle: {
                            const d = entry.modelData;
                            if (d.kind === "app") return d.app.comment || d.app.genericName || "";
                            if (d.kind === "calc") return "Copy result";
                            if (d.kind === "web") return "DuckDuckGo";
                            if (d.kind === "file") return win.dirName(d.path);
                            return "";
                        }
                        // Material Symbols glyph for the non-app rows
                        readonly property string glyph: {
                            const d = entry.modelData;
                            if (d.kind === "calc") return "calculate";
                            if (d.kind === "web") return "travel_explore";
                            if (d.kind === "file") return d.isDir ? "folder" : "draft";
                            return "search";
                        }
                        width: ListView.view.width
                        height: 56

                        // Hover state layer
                        Rectangle {
                            anchors.fill: parent
                            radius: 18
                            color: Theme.fg1
                            opacity: rowArea.pressed ? 0.10 : rowArea.containsMouse && !entry.current ? 0.05 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 14
                            spacing: 14

                            // Icon in a tonal tile that lights up when selected
                            Rectangle {
                                implicitWidth: 40
                                implicitHeight: 40
                                radius: entry.current ? 14 : 20
                                color: entry.current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : BarConfig.surface(Theme.bg2)
                                Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 180 } }
                                IconImage {
                                    anchors.centerIn: parent
                                    visible: entry.isApp
                                    implicitSize: 26
                                    scale: entry.current ? 1.08 : 1
                                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                                    source: entry.isApp ? Quickshell.iconPath(entry.modelData.app.icon, "application-x-executable") : ""
                                }
                                // Calculator, web and file rows use a Material Symbols glyph
                                Text {
                                    anchors.centerIn: parent
                                    visible: !entry.isApp
                                    text: entry.glyph
                                    color: entry.current ? Theme.accent : Theme.fg1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    font.family: Theme.iconFont
                                    font.variableAxes: Theme.iconAxes
                                    font.pixelSize: 26
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: entry.title
                                    color: entry.current ? Theme.accent : Theme.fg1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 1
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== "" && (entry.isApp ? Config.launcher.showDescriptions : true)
                                    text: entry.subtitle
                                    color: Theme.fg2
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                    elide: Text.ElideRight
                                }
                            }

                            // "Enter" hint slides in on the selected row
                            Text {
                                text: "keyboard_return"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.variableAxes: Theme.iconAxes
                                font.pixelSize: Theme.fontSize + 2
                                opacity: entry.current ? 1 : 0
                                transform: Translate { x: entry.current ? 0 : -8 }
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = entry.index
                            onClicked: win.activate(entry.modelData)
                        }
                    }

                    // Nothing matches
                    Column {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        spacing: 8
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "search_off"; color: Theme.fg2; font.family: Theme.iconFont; font.variableAxes: Theme.iconAxes; font.pixelSize: 36 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: `Nothing found for "${search.text}"`; color: Theme.fg2; font.family: Theme.font; font.pixelSize: Theme.fontSize }
                    }
                }
            }
        }
    }
}

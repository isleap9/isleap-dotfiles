import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// Main monitor, which monitors show a bar, and every display setting: resolution,
// refresh rate, scale, arrangement, VRR, mirroring, HDR and ICC profiles.
// The rules live in Displays.qml, which writes ~/.config/hypr/modules/monitors.lua;
// Hyprland applies that file the moment it is saved.
Page {
    id: page

    property string selectedName: ""      // monitor being edited below
    property bool advanced: false         // show the color / bit depth rows
    property string problem: ""           // last validation problem (shown in red)
    property string hint: ""              // "Changes reverted" and similar
    property var identifyNames: []        // monitors currently showing their name

    // Dragging a box in the arrangement diagram. Only one box can be dragged, so the
    // offset lives here instead of in every box: the boxes keep their bindings.
    property string dragName: ""          // monitor under the pointer ("" = none)
    property bool dragMoved: false        // the pointer passed the drag threshold
    property real dragDX: 0               // pointer travel from the box's laid-out spot
    property real dragDY: 0
    property real dragPressX: 0           // press point, in diagram coordinates
    property real dragPressY: 0
    readonly property int dragThreshold: 6    // px before a press becomes a drag
    readonly property int snapDistance: 20    // logical px for magnetic edge/center snaps

    readonly property var monitors: Displays.monitors
    readonly property string mainName: Globals.mainScreen ? Globals.mainScreen.name : ""

    // The monitor being edited (falls back to the first one)
    readonly property var selected: {
        const list = page.monitors;
        for (const m of list) if (m.name === page.selectedName) return m;
        return list.length > 0 ? list[0] : null;
    }
    readonly property string selName: page.selected ? page.selected.name : ""
    readonly property var sel: Displays.desiredFor(page.selName)

    readonly property string selMode: page.sel.mode ? String(page.sel.mode) : ""

    readonly property string selResolution: {
        const r = Displays.modeRes(page.selMode);
        if (r) return r.w + "x" + r.h;
        return page.selected ? String(page.selected.width) + "x" + String(page.selected.height) : "";
    }

    readonly property string selRate: {
        if (page.selMode === "preferred") return "preferred";
        const r = Displays.modeRate(page.selMode);
        if (r !== "") return r;
        return page.selected ? Displays.fmtRate(page.selected.refreshRate) : "";
    }

    readonly property int transformValue: {
        const t = Number(page.sel.transform);
        return isFinite(t) ? t : 0;
    }

    readonly property var resolutionOptions: {
        const out = [];
        const list = Displays.uniqueResolutions(page.selected);
        for (const r of list) out.push({ value: r, label: String(r).replace("x", " × ") });
        return out;
    }

    readonly property var rateOptions: {
        const out = [{ value: "preferred", label: "Preferred" }];
        const rates = Displays.ratesFor(page.selected, page.selResolution);
        for (const r of rates) out.push({ value: r, label: r + " Hz" });
        return out;
    }

    readonly property var mirrorOptions: {
        const out = [{ value: "", label: "None" }];
        for (const m of page.monitors)
            if (m.name !== page.selName) out.push({ value: m.name, label: m.name + " — " + page.label(m) });
        return out;
    }

    readonly property var cmOptions: [
        { value: "auto", label: "Auto" },
        { value: "srgb", label: "sRGB" },
        { value: "dcip3", label: "Display P3" },
        { value: "dp3", label: "DP3" },
        { value: "adobe", label: "Adobe RGB" },
        { value: "wide", label: "Wide gamut" },
        { value: "hdr", label: "HDR (experimental)" },
        { value: "hdredid", label: "HDR from EDID (experimental)" }
    ]

    readonly property string scaleWarning: page.selName !== "" ? Displays.validateScale(page.selName) : ""
    readonly property string overlapWarning: page.selName !== "" ? Displays.validateOverlap(page.selName) : ""
    readonly property bool hdrOn: page.sel.cm === "hdr" || page.sel.cm === "hdredid"

    Component.onCompleted: {
        page.selectDefault();
        Displays.refresh();
    }
    onMonitorsChanged: page.selectDefault()

    function selectDefault() {
        if (page.selectedName !== "") return;
        if (page.mainName !== "") page.selectedName = page.mainName;
        else if (page.monitors.length > 0) page.selectedName = page.monitors[0].name;
    }

    function label(m) {
        if (!m) return "";
        return [m.make, m.model].filter(x => x && x !== "Unknown").join(" ") || m.description || m.name;
    }

    // Validation problems in red inside an Option's description
    function warn(text, color) {
        if (!text) return "";
        return '<font color="' + color + '">' + text + '</font>';
    }

    function enabledCount() {
        let n = 0;
        for (const m of Displays.monitors) {
            const d = Displays.desired[m.name];
            if (!d || d.disabled !== true) n++;
        }
        return n;
    }

    // One place where every control lands: change `desired`, write the file, start the
    // countdown for risky fields. A validation problem is shown, nothing is written and
    // the control snaps back. `name` is the monitor being edited; the diagram passes the
    // box that was dragged, everything else uses the selected monitor.
    function commit(fields, risky, name) {
        const who = name ? name : page.selName;
        if (who === "") return;
        const wasPending = Displays.pending;
        const before = Displays.clone(Displays.desiredFor(who));
        // Snapshot before the change: Revert puts the old file and the old values back
        if (risky === true && !wasPending) Displays.snapshot();
        Displays.update(who, fields);
        const problem = Displays.apply(risky === true);
        page.problem = problem;
        if (problem !== "") {
            Displays.update(who, before);
            return;
        }
        // The countdown banner sits at the top of the page: make sure it's seen
        if (!wasPending && Displays.pending) page.contentY = 0;
    }

    function setEnabled(on) {
        if (!on && page.enabledCount() <= 1) {
            page.problem = "You can't disable the only monitor";
            return;
        }
        page.commit({ disabled: !on }, true);
    }

    function setPosition(text) {
        const t = String(text).trim();
        if (!/^-?[0-9]+x-?[0-9]+$/.test(t)) {
            page.problem = "Position should look like 1920x0";
            return;
        }
        page.commit({ position: t }, true);
    }

    // ── Drag editor ──
    // Where the dragged box would land: an absolute logical position, magnetically
    // snapped to the other monitors' edges and centers. null when nothing is dragged.
    readonly property var dragCandidate: {
        const name = page.dragName;
        if (name === "" || !page.dragMoved) return null;
        const box = page.boxFor(name);
        if (!box) return null;

        // Undo the diagram's scaling: the box is drawn at visualX(monitor.x)
        let x = diagram.logicalX(diagram.visualX(box.x) + page.dragDX);
        let y = diagram.logicalY(diagram.visualY(box.y) + page.dragDY);
        if (!isFinite(x) || !isFinite(y)) return null;

        // Edges and centers of the other monitors are the magnets
        const targetsX = [];
        const targetsY = [];
        for (const b of diagram.boxes) {
            if (b.m.name === name || b.m.disabled === true) continue;
            targetsX.push(b.x, b.x + b.w, b.x + b.w / 2);
            targetsY.push(b.y, b.y + b.h, b.y + b.h / 2);
        }
        const sx = page.snapAxis(x, box.w, targetsX);
        const sy = page.snapAxis(y, box.h, targetsY);
        x = page.clampPosition(Math.round(sx.pos));
        y = page.clampPosition(Math.round(sy.pos));

        // A drop on top of another monitor is refused
        const other = Displays.overlapsAt(name, x, y);
        return {
            name: name, x: x, y: y, text: x + "x" + y,
            valid: other === "", other: other,
            guideX: sx.guide, guideY: sy.guide
        };
    }

    function boxFor(name) {
        for (const b of diagram.boxes) if (b.m.name === name) return b;
        return null;
    }

    // Nearest edge / center alignment on one axis, within snapDistance logical pixels.
    // `guide` is the target coordinate the snap lined up with (null = no snap).
    function snapAxis(value, size, targets) {
        let best = value;
        let guide = null;
        let bestDist = page.snapDistance + 1;
        const anchors = [0, size, size / 2];    // our left, right and center
        for (const t of targets) {
            for (const a of anchors) {
                const pos = t - a;
                const dist = Math.abs(pos - value);
                if (dist <= page.snapDistance && dist < bestDist) {
                    bestDist = dist;
                    best = pos;
                    guide = t;
                }
            }
        }
        return { pos: best, guide: guide };
    }

    // Hyprland is fine with negative coordinates, not with absurd ones
    function clampPosition(v) {
        return Math.max(-20000, Math.min(20000, v));
    }

    function startDrag(name, x, y) {
        page.dragName = name;
        page.dragMoved = false;
        page.dragDX = 0;
        page.dragDY = 0;
        page.dragPressX = x;
        page.dragPressY = y;
    }

    // A press only becomes a drag once the pointer has travelled dragThreshold pixels
    function moveDrag(x, y) {
        if (page.dragName === "") return;
        const dx = x - page.dragPressX;
        const dy = y - page.dragPressY;
        if (!page.dragMoved && Math.hypot(dx, dy) <= page.dragThreshold) return;
        page.dragMoved = true;
        page.dragDX = dx;
        page.dragDY = dy;
    }

    function endDrag() {
        page.dragName = "";
        page.dragDX = 0;
        page.dragDY = 0;
    }

    // Released: a free spot is committed like any other risky change, an overlap springs
    // back (the box offsets are cleared, so its bindings take over again).
    function dropMonitor() {
        const cand = page.dragCandidate;
        const moved = page.dragMoved;
        page.endDrag();
        if (!moved || cand === null) return;
        if (!cand.valid) {
            page.problem = cand.name + " would overlap " + cand.other + " — move it somewhere free";
            return;
        }
        page.commit({ position: cand.text }, true, cand.name);
    }

    function setIcc(text) {
        const t = String(text).trim();
        if (t !== "" && t.charAt(0) !== "/") {
            page.problem = "ICC profile path must be absolute (start with /)";
            return;
        }
        page.commit({ icc: t }, false);
    }

    function identify(name) {
        if (!name) return;
        const list = page.identifyNames.filter(n => n !== name);
        list.push(name);
        page.identifyNames = list;
    }

    function stopIdentify(name) {
        page.identifyNames = page.identifyNames.filter(n => n !== name);
    }

    Connections {
        target: Displays
        function onReverted() {
            page.hint = "Changes reverted";
            page.problem = "";
            hintTimer.restart();
        }
        function onIdentifyRequested(name) { page.identify(name); }
    }

    Timer { id: hintTimer; interval: 3500; onTriggered: page.hint = "" }

    // Monitors can be unplugged while their name is on screen
    Connections {
        target: Quickshell
        function onScreensChanged() {
            page.identifyNames = page.identifyNames.filter(n => Quickshell.screens.some(s => s.name === n));
        }
    }

    // ── Pending-change banner (top of the page, always seen when a change lands) ──
    Rectangle {
        visible: Displays.pending
        Layout.fillWidth: true
        implicitHeight: 62
        radius: 18
        color: Theme.bg1
        border.width: 1
        border.color: Theme.accent

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 10
            spacing: 12

            Text {
                text: "timer"
                color: Theme.accent
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxes
                font.pixelSize: Theme.fontSize + 4
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: "Reverting in " + Displays.revertIn + " s unless you keep the new settings"
                    color: Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Displays.synced ? "Applied — check the screens" : "Waiting for Hyprland to apply the new monitors.lua…"
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    elide: Text.ElideRight
                }
            }
            PillButton { text: "Keep changes"; primary: true; onClicked: Displays.keep() }
            PillButton { text: "Revert now"; onClicked: Displays.revert() }
        }
    }

    // ── Transient hint ("Changes reverted") ──
    Text {
        visible: page.hint !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 8
        text: page.hint
        color: Theme.fg2
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }

    // ── Your monitors ──
    Section {
        title: "Your monitors"
        description: "Drag a monitor to arrange it — edges and centers snap. Click one to select it and make it your main monitor."

        // Scaled picture of the real arrangement
        Item {
            id: diagram
            Layout.fillWidth: true
            Layout.margins: 12
            implicitHeight: 240

            // Logical size of each monitor (pixels / scale) and the area they cover together
            readonly property var boxes: page.monitors.map(m => ({
                m, x: m.x, y: m.y, w: m.width / (m.scale || 1), h: m.height / (m.scale || 1)
            }))
            readonly property real minX: Math.min(...boxes.map(b => b.x), 0)
            readonly property real minY: Math.min(...boxes.map(b => b.y), 0)
            readonly property real spanW: Math.max(...boxes.map(b => b.x + b.w), 1) - minX
            readonly property real spanH: Math.max(...boxes.map(b => b.y + b.h), 1) - minY
            readonly property real k: Math.min((width - 8) / spanW, (height - 8) / spanH)
            readonly property real offX: (width - spanW * k) / 2
            readonly property real offY: (height - spanH * k) / 2

            // The boxes are drawn at offX + (logical - minX) * k + 3: these convert
            // between the picture and the logical pixels Hyprland positions monitors in,
            // so a drag lands on exactly the numbers it was drawn from.
            function visualX(lx) { return offX + (lx - minX) * k + 3 }
            function visualY(ly) { return offY + (ly - minY) * k + 3 }
            function logicalX(vx) { return k > 0 ? (vx - 3 - offX) / k + minX : 0 }
            function logicalY(vy) { return k > 0 ? (vy - 3 - offY) / k + minY : 0 }

            Repeater {
                model: diagram.boxes

                Rectangle {
                    id: screenBox
                    required property var modelData
                    readonly property var mon: modelData.m
                    readonly property bool isMain: mon.name === page.mainName
                    readonly property bool isSelected: mon.name === page.selName
                    readonly property bool hasBar: !(Config.monitors.barHidden ?? []).includes(mon.name)
                    readonly property bool isDragged: page.dragName === mon.name
                    readonly property var cand: screenBox.isDragged ? page.dragCandidate : null
                    readonly property bool dropBad: screenBox.cand !== null && !screenBox.cand.valid

                    // While this box is dragged, its offset is added on top of the layout
                    x: diagram.visualX(modelData.x) + (screenBox.isDragged ? page.dragDX : 0)
                    y: diagram.visualY(modelData.y) + (screenBox.isDragged ? page.dragDY : 0)
                    width: modelData.w * diagram.k - 6
                    height: modelData.h * diagram.k - 6
                    z: screenBox.isDragged ? 1 : 0
                    radius: 12
                    color: isMain ? Theme.bg3 : Theme.bg2
                    border.width: screenBox.dropBad || screenBox.cand !== null ? 3
                        : isMain || isSelected ? 3 : boxArea.containsMouse ? 2 : 1
                    border.color: screenBox.dropBad ? Theme.red
                        : screenBox.cand !== null ? Theme.accent
                        : isMain || isSelected ? Theme.accent
                        : boxArea.containsMouse ? Theme.fg2 : Theme.bg4

                    // Subtle ring around the monitor being edited
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -5
                        radius: 16
                        color: "transparent"
                        border.width: 2
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                        visible: screenBox.isSelected && !screenBox.isMain
                    }

                    // Drag to arrange, click to select. The Identify pill above still wins.
                    MouseArea {
                        id: boxArea
                        anchors.fill: parent
                        hoverEnabled: true
                        // The page is a Flickable: without this a drag turns into a scroll
                        preventStealing: true
                        cursorShape: screenBox.isDragged && page.dragMoved ? Qt.ClosedHandCursor
                            : boxArea.containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onPressed: mouse => {
                            const p = boxArea.mapToItem(diagram, mouse.x, mouse.y);
                            page.startDrag(screenBox.mon.name, p.x, p.y);
                        }
                        onPositionChanged: mouse => {
                            if (!boxArea.pressed) return;
                            const p = boxArea.mapToItem(diagram, mouse.x, mouse.y);
                            page.moveDrag(p.x, p.y);
                        }
                        onReleased: page.dropMonitor()
                        onCanceled: page.endDrag()
                        onClicked: {
                            // A drag is not a click: dropMonitor already ran on release
                            if (page.dragMoved) {
                                page.dragMoved = false;
                                return;
                            }
                            page.selectedName = screenBox.mon.name;
                            Config.monitors.main = screenBox.mon.name;
                        }
                    }

                    // Bar strip, if this monitor shows a bar
                    Rectangle {
                        visible: screenBox.hasBar
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        y: BarConfig.bottom ? parent.height - 16 : 8
                        height: 6
                        radius: 3
                        color: screenBox.isMain ? Theme.accent : Theme.fg2
                        opacity: 0.6
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (screenBox.isMain ? "star  " : "") + screenBox.mon.name
                            color: Theme.fg1
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: Theme.fontSize + 2
                            font.weight: Font.Bold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: `${screenBox.mon.width}×${screenBox.mon.height} · ${Math.round(screenBox.mon.refreshRate)} Hz`
                            color: Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: screenBox.isMain
                            text: "Main"
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.Black
                        }
                        PillButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: screenBox.isSelected
                            text: "Identify"
                            icon: "sensors"
                            onClicked: page.identify(screenBox.mon.name)
                        }
                    }

                    // Candidate position while dragging; red when the drop is refused
                    Rectangle {
                        id: posChip
                        readonly property var cand: screenBox.cand

                        visible: posChip.cand !== null
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        width: chipRow.implicitWidth + 16
                        height: 20
                        radius: 10
                        color: Theme.bg0
                        border.width: 1
                        border.color: screenBox.dropBad ? Theme.red : Theme.accent

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: posChip.cand ? posChip.cand.text : ""
                                color: screenBox.dropBad ? Theme.red : Theme.accent
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 4
                                font.weight: Font.Bold
                            }
                            Text {
                                visible: screenBox.dropBad
                                text: "overlap"
                                color: Theme.red
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 4
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }

            // Alignment guides, drawn while a magnetic snap is active
            Rectangle {
                readonly property var cand: page.dragCandidate
                visible: cand !== null && cand.guideX !== null
                x: visible ? diagram.visualX(cand.guideX) : 0
                y: 0
                width: 1
                height: diagram.height
                color: Theme.accent
                opacity: 0.8
            }
            Rectangle {
                readonly property var cand: page.dragCandidate
                visible: cand !== null && cand.guideY !== null
                x: 0
                y: visible ? diagram.visualY(cand.guideY) : 0
                width: diagram.width
                height: 1
                color: Theme.accent
                opacity: 0.8
            }

            Text {
                anchors.centerIn: parent
                visible: page.monitors.length === 0
                text: "Reading monitors…"
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }
    }

    // ── Main monitor ──
    Section {
        title: "Main monitor"
        Option {
            icon: "star"
            label: "Main monitor"
            description: Config.monitors.main === "" ? "Not set — using the biggest screen" : ""
            Segmented {
                options: page.monitors.map(m => [m.name, m.name])
                current: page.mainName
                onSelected: v => Config.monitors.main = v
            }
        }
        Option {
            icon: "menu"
            label: "Open popups on"
            description: Config.monitors.popups === "main"
                ? "Launcher, control center, notifications and power menu always open on the main monitor"
                : "They open on the monitor you're working on"
            Segmented {
                options: [["focused", "Focused monitor"], ["main", "Main monitor"]]
                current: Config.monitors.popups
                onSelected: v => Config.monitors.popups = v
            }
        }
    }

    // ── Bar ──
    Section {
        title: "Bar"
        description: "Choose which monitors show the bar"

        Repeater {
            model: page.monitors

            Option {
                id: barRow
                required property var modelData
                icon: "toolbar"
                label: `${modelData.name} — ${page.label(modelData)}`
                description: modelData.name === page.mainName ? "Main monitor" : ""
                Toggle {
                    checked: !(Config.monitors.barHidden ?? []).includes(barRow.modelData.name)
                    onToggled: {
                        const hidden = (Config.monitors.barHidden ?? []).filter(n => n !== barRow.modelData.name);
                        if (checked) hidden.push(barRow.modelData.name);
                        Config.monitors.barHidden = hidden;
                    }
                }
            }
        }
    }

    // ── Display settings for the selected monitor ──
    Section {
        title: "Display settings"
        description: "Click a monitor in the layout above to edit it. Changes that can blank a screen revert after 12 seconds unless you keep them."

        // Every monitor, in case the boxes are hard to click
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 12

            Text {
                text: "Editing"
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
            Segmented {
                options: page.monitors.map(m => [m.name, m.name])
                current: page.selName
                onSelected: v => page.selectedName = v
            }
            Item { Layout.fillWidth: true }
            PillButton {
                text: "Open monitors.lua"
                icon: "edit"
                onClicked: Quickshell.execDetached(["kitty", "-e", "micro", Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"])
            }
        }

        Option {
            icon: "monitor"
            label: "Monitor"
            description: page.selected ? page.label(page.selected) : ""
            Segmented {
                options: page.monitors.map(m => [m.name, m.name])
                current: page.selName
                onSelected: v => page.selectedName = v
            }
        }

        Option {
            icon: "aspect_ratio"
            label: "Resolution"
            description: "The monitor's native resolution is the sharpest"
            Dropdown {
                options: page.resolutionOptions
                current: page.selResolution
                onSelected: v => {
                    const rates = Displays.ratesFor(page.selected, v);
                    let rate = page.selRate;
                    if (rate === "preferred" || !rates.includes(rate)) rate = rates.length > 0 ? rates[0] : "";
                    page.commit({ mode: rate === "" ? "preferred" : v + "@" + rate }, true);
                }
            }
        }

        Option {
            icon: "speed"
            label: "Refresh rate"
            description: "Preferred lets the monitor pick its best mode"
            Dropdown {
                options: page.rateOptions
                current: page.selRate
                onSelected: v => page.commit({ mode: v === "preferred" ? "preferred" : page.selResolution + "@" + v }, true)
            }
        }

        Option {
            icon: "photo_size_select_large"
            label: "Scale"
            description: page.scaleWarning !== ""
                ? page.warn(page.scaleWarning, Theme.red)
                : "1 = native. 1.25 and 1.5 keep text crisp"
            Stepper {
                value: page.sel.scale ? page.sel.scale : 1
                from: 0.5
                to: 4
                step: 0.25
                decimals: 2
                onChanged: v => page.commit({ scale: v }, true)
            }
        }

        Option {
            icon: "screen_rotation"
            label: "Orientation"
            description: page.transformValue >= 4 ? "Flipped" : "Normal orientation"
            RowLayout {
                spacing: 10
                Segmented {
                    options: [[0, "Normal"], [1, "90°"], [2, "180°"], [3, "270°"]]
                    current: page.transformValue % 4
                    onSelected: v => page.commit({ transform: v + (page.transformValue >= 4 ? 4 : 0) }, true)
                }
                Toggle {
                    checked: page.transformValue >= 4
                    onToggled: page.commit({ transform: (page.transformValue % 4) + (checked ? 0 : 4) }, true)
                }
            }
        }

        Option {
            icon: "sync"
            label: "Variable refresh rate (VRR)"
            description: "Applies instantly — it can't blank the screen"
            Toggle {
                checked: Number(page.sel.vrr) > 0
                onToggled: page.commit({ vrr: checked ? 0 : 1 }, false)
            }
        }

        Option {
            icon: "content_copy"
            label: "Mirror of"
            description: "Shows the same picture as another monitor"
            Dropdown {
                options: page.mirrorOptions
                current: page.sel.mirror ? page.sel.mirror : ""
                onSelected: v => page.commit({ mirror: v }, true)
            }
        }

        Option {
            icon: "power_settings_new"
            label: "Monitor enabled"
            description: page.sel.disabled === true
                ? "Disabled — its windows and workspaces move to the other monitor"
                : "Disabling moves all its windows and workspaces to the other monitor."
            Toggle {
                checked: page.sel.disabled !== true
                onToggled: page.setEnabled(!checked)
            }
        }

        Option {
            icon: "open_with"
            label: "Position"
            description: page.overlapWarning !== ""
                ? page.warn(page.overlapWarning, Theme.red)
                : "Logical pixels from the top-left of the arrangement"
            ColumnLayout {
                spacing: 8
                RowLayout {
                    spacing: 6
                    PillButton { text: "Right of others"; onClicked: page.commit({ position: "auto-right" }, true) }
                    PillButton { text: "Left"; onClicked: page.commit({ position: "auto-left" }, true) }
                }
                RowLayout {
                    spacing: 6
                    PillButton { text: "Above"; onClicked: page.commit({ position: "auto-up" }, true) }
                    PillButton { text: "Below"; onClicked: page.commit({ position: "auto-down" }, true) }
                }
                TextBox {
                    text: page.sel.position && String(page.sel.position).indexOf("auto") !== 0 ? String(page.sel.position) : ""
                    placeholder: page.selected ? (page.selected.x + "x" + page.selected.y) : "1920x0"
                    onAccepted: v => page.setPosition(v)
                }
            }
        }

        Option {
            icon: "sensors"
            label: "Identify"
            description: "Shows the monitor's name on it for a few seconds"
            PillButton {
                text: "Identify"
                onClicked: page.identify(page.selName)
            }
        }

        Option {
            icon: "lightbulb"
            label: "Screen"
            description: "Not saved — the screen turns back on after a reload"
            Toggle {
                checked: page.selected ? page.selected.dpmsStatus === true : false
                onToggled: Displays.setDpms(page.selName, !checked)
            }
        }

        // Validation problems are shown here too, so they're not missed while scrolled
        Text {
            visible: page.problem !== ""
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 10
            text: page.problem
            color: Theme.red
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            wrapMode: Text.Wrap
        }
    }

    // ── Advanced (color, bit depth, ICC) ──
    Section {
        title: "Advanced"
        description: "Color and bit depth for " + (page.selName !== "" ? page.selName : "the selected monitor") + ". Only change these if you know what they do."

        Option {
            icon: "tune"
            label: "Show advanced settings"
            Toggle {
                checked: page.advanced
                onToggled: page.advanced = !checked
            }
        }

        Option {
            visible: page.advanced
            icon: "gradient"
            label: "Bit depth"
            description: page.sel.bitdepth === 10
                ? page.warn("Many apps and captures have issues with 10-bit", Theme.orange)
                : "8-bit is the safe default"
            Segmented {
                options: [[8, "8-bit"], [10, "10-bit"]]
                current: Number(page.sel.bitdepth) === 10 ? 10 : 8
                onSelected: v => page.commit({ bitdepth: v }, false)
            }
        }

        Option {
            visible: page.advanced
            icon: "palette"
            label: "Color management"
            description: page.hdrOn ? "HDR is experimental on Hyprland" : "sRGB is the safe default"
            Dropdown {
                options: page.cmOptions
                current: page.sel.cm ? page.sel.cm : "srgb"
                onSelected: v => page.commit({ cm: v }, false)
            }
        }

        Option {
            visible: page.advanced && page.hdrOn
            icon: "brightness_6"
            label: "SDR brightness"
            description: "How bright SDR content looks in HDR mode"
            Stepper {
                value: page.sel.sdrbrightness ? page.sel.sdrbrightness : 1
                from: 0.5
                to: 2
                step: 0.05
                decimals: 2
                onChanged: v => page.commit({ sdrbrightness: v }, false)
            }
        }

        Option {
            visible: page.advanced && page.hdrOn
            icon: "water_drop"
            label: "SDR saturation"
            description: "Color intensity of SDR content in HDR mode"
            Stepper {
                value: page.sel.sdrsaturation ? page.sel.sdrsaturation : 1
                from: 0
                to: 2
                step: 0.05
                decimals: 2
                onChanged: v => page.commit({ sdrsaturation: v }, false)
            }
        }

        Option {
            visible: page.advanced
            icon: "description"
            label: "ICC profile"
            description: "Absolute path to a .icc / .icm file. Empty = none"
            TextBox {
                text: page.sel.icc ? page.sel.icc : ""
                placeholder: "/usr/share/color/icc/profile.icc"
                onAccepted: v => page.setIcc(v)
            }
        }
    }

    // ── Identify overlays: one big name in the middle of each chosen screen ──
    Variants {
        model: page.identifyNames

        PanelWindow {
            id: idWin
            required property string modelData
            readonly property var monScreen: Quickshell.screens.find(s => s.name === idWin.modelData)

            screen: idWin.monScreen ? idWin.monScreen : Quickshell.screens[0]
            visible: idWin.monScreen !== undefined
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-identify"
            mask: Region {}

            Timer {
                interval: 3000
                running: true
                onTriggered: page.stopIdentify(idWin.modelData)
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 120, 560)
                height: 200
                radius: 28
                color: Theme.bg0
                border.width: 3
                border.color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: idWin.modelData
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 96
                    font.weight: Font.Black
                }
            }
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Monitor settings for the whole shell.
// Reads the live state with `hyprctl monitors all -j`, keeps the desired rules for
// ~/.config/hypr/modules/monitors.lua and writes that file. Hyprland watches it and
// applies it the moment it is saved, so writing the file IS the apply path.
// Risky changes (mode, scale, position, transform, mirror, enabled) auto-revert after
// 12 seconds unless the user keeps them.
Singleton {
    id: root

    // ── Live state ──
    property var monitors: []          // parsed `hyprctl monitors all -j`
    property bool queued: false        // a refresh was asked for while one was running

    // ── What monitors.lua should say: name → rule fields ──
    property var desired: ({})
    // Before the first risky change: { desired, text } (text = the old file, restored verbatim)
    property var lastGood: null
    property bool pending: false       // a risky change is waiting for Keep
    property bool synced: true         // the live state matches `desired`
    property bool awaiting: false      // a write just landed; check `synced` on the next refresh
    readonly property int revertSeconds: 12
    property int revertIn: 0

    signal reverted()
    signal identifyRequested(string name)

    readonly property string luaPath: Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"

    // ── Reading the live state ──
    // A moment after startup: hyprctl can finish before a process started at construction
    // time is wired up, and its output would be lost.
    Timer { interval: 200; running: true; onTriggered: root.refresh() }

    function refresh() {
        if (query.running) { queued = true; return; }
        query.running = true;
    }

    Process {
        id: query
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            id: queryOut
            onStreamFinished: root.ingest(queryOut.text)
        }
        onExited: {
            if (root.queued) { root.queued = false; root.refresh(); }
        }
    }

    function ingest(text) {
        let list = [];
        try { list = JSON.parse(text); } catch (e) { list = []; }
        if (!Array.isArray(list)) list = [];
        monitors = list;

        // First refresh fills the map. A monitor plugged in later gets an entry too,
        // but nothing is written: only the user's changes write the file.
        let next = clone(desired);
        let added = false;
        for (const m of list) {
            if (!next[m.name]) { next[m.name] = seed(m); added = true; }
        }
        if (added) desired = next;

        if (awaiting) {
            awaiting = false;
            checkSynced();
            // Hyprland may need a moment more to apply the file
            if (!synced && retries < 4) { retries++; retryTimer.restart(); }
            else retries = 0;
        } else if (pending) checkSynced();
    }

    // ── Seeding `desired` from a live monitor ──
    function seedDefaults() {
        return {
            mode: "", position: "0x0", scale: 1, transform: 0, vrr: 0,
            disabled: false, mirror: "", bitdepth: 8, cm: "srgb", icc: "",
            sdrbrightness: 1, sdrsaturation: 1
        };
    }

    function seed(m) {
        const d = seedDefaults();
        d.mode = seedMode(m);
        d.position = String(m.x) + "x" + String(m.y);
        d.scale = m.scale ? m.scale : 1;
        d.transform = m.transform ? m.transform : 0;
        d.vrr = m.vrr ? 1 : 0;
        d.disabled = m.disabled === true;
        d.mirror = m.mirrorOf && m.mirrorOf !== "none" ? m.mirrorOf : "";
        d.cm = m.colorManagementPreset ? m.colorManagementPreset : "srgb";
        d.sdrbrightness = m.sdrBrightness ? m.sdrBrightness : 1;
        d.sdrsaturation = m.sdrSaturation ? m.sdrSaturation : 1;
        return d;
    }

    // The availableModes entry closest to the current refresh rate, without the "Hz"
    function seedMode(m) {
        let best = "";
        let bestDiff = 1000000;
        const modes = m.availableModes ? m.availableModes : [];
        for (const s of modes) {
            const p = parseAvailable(s);
            if (p.w !== m.width || p.h !== m.height) continue;
            const diff = Math.abs(p.rate - m.refreshRate);
            if (diff < bestDiff) {
                bestDiff = diff;
                best = p.w + "x" + p.h + "@" + fmtRate(p.rate);
            }
        }
        if (best === "") best = m.width + "x" + m.height + "@" + fmtRate(m.refreshRate);
        return best;
    }

    // ── Helpers ──
    function clone(o) {
        if (o === undefined || o === null) return {};
        return JSON.parse(JSON.stringify(o));
    }

    function monitorFor(name) {
        for (const m of monitors) if (m.name === name) return m;
        return null;
    }

    function desiredFor(name) {
        const d = desired[name];
        return d ? d : {};
    }

    function update(name, fields) {
        if (!name) return;
        const next = clone(desired);
        const live = monitorFor(name);
        const cur = next[name] ? next[name] : (live ? seed(live) : seedDefaults());
        for (const k in fields) cur[k] = fields[k];
        next[name] = cur;
        desired = next;
        synced = false;
    }

    function parseAvailable(s) {
        const at = s.split("@");
        const wh = at[0].split("x");
        return {
            w: parseInt(wh[0]),
            h: parseInt(wh[1]),
            rate: at.length > 1 ? Number(at[1].replace("Hz", "")) : 0
        };
    }

    function modeRes(mode) {
        if (!mode) return null;
        const at = String(mode).split("@");
        const wh = at[0].split("x");
        if (wh.length !== 2) return null;
        const w = parseInt(wh[0]);
        const h = parseInt(wh[1]);
        if (!isFinite(w) || !isFinite(h) || w <= 0 || h <= 0) return null;
        return { w: w, h: h };
    }

    function modeRate(mode) {
        if (!mode) return "";
        const at = String(mode).split("@");
        return at.length > 1 ? at[1] : "";
    }

    function fmtRate(r) {
        const n = Number(r);
        if (!isFinite(n)) return String(r);
        return String(Number(n.toFixed(2)));
    }

    function fmtNum(n) {
        const v = Number(n);
        if (!isFinite(v)) return "1";
        return String(Number(v.toFixed(3)));
    }

    // Every distinct resolution the monitor offers, biggest first
    function uniqueResolutions(m) {
        const seen = {};
        const out = [];
        const modes = m && m.availableModes ? m.availableModes : [];
        for (const s of modes) {
            const wh = s.split("@")[0];
            if (!seen[wh]) { seen[wh] = true; out.push(wh); }
        }
        out.sort((a, b) => areaOf(b) - areaOf(a));
        return out;
    }

    function areaOf(wh) {
        const p = String(wh).split("x");
        return Number(p[0]) * Number(p[1]);
    }

    // Refresh rates for one resolution, highest first, deduped and without "Hz"
    function ratesFor(m, res) {
        const seen = {};
        const out = [];
        const modes = m && m.availableModes ? m.availableModes : [];
        for (const s of modes) {
            const parts = s.split("@");
            if (parts[0] !== res || parts.length < 2) continue;
            const r = fmtRate(parts[1].replace("Hz", ""));
            if (!seen[r]) { seen[r] = true; out.push(r); }
        }
        out.sort((a, b) => Number(b) - Number(a));
        return out;
    }

    // ── The file ──
    FileView {
        id: luaFile
        path: root.luaPath
        watchChanges: true
        onFileChanged: fileTimer.restart()
    }

    // Hand edits / nwg-displays writes also land here: re-read the live state after them
    Timer { id: fileTimer; interval: 400; onTriggered: root.refresh() }
    // Our own write: Hyprland needs a moment to apply it before the state matches
    Timer { id: writeTimer; interval: 900; onTriggered: root.refresh() }
    Timer { id: revertTimer; interval: 1000; repeat: true; onTriggered: root.tick() }
    property int retries: 0
    Timer { id: retryTimer; interval: 1200; onTriggered: root.refresh() }

    // Raw text write: FileView.setText() (no adapter needed). It writes atomically,
    // so Hyprland's file watch sees one complete file.
    function writeText(t) {
        retries = 0;
        luaFile.setText(t);
        writeTimer.restart();
    }

    function buildLua() {
        const names = Object.keys(desired).sort();
        const rows = [];
        for (const n of names) {
            const d = desired[n] ? desired[n] : seedDefaults();
            if (d.disabled === true) {
                rows.push(['output = "' + n + '"', "disabled = true"]);
                continue;
            }
            const t = [];
            t.push('output = "' + n + '"');
            t.push('mode = "' + String(d.mode) + '"');
            t.push('position = "' + String(d.position) + '"');
            t.push("scale = " + fmtNum(d.scale));
            if (Number(d.transform) !== 0) t.push("transform = " + Math.round(Number(d.transform)));
            if (Number(d.vrr) !== 0) t.push("vrr = " + Math.round(Number(d.vrr)));
            if (d.mirror && d.mirror !== "none") t.push('mirror = "' + d.mirror + '"');
            if (Number(d.bitdepth) !== 8 && d.bitdepth !== undefined) t.push("bitdepth = " + Math.round(Number(d.bitdepth)));
            if (d.cm && d.cm !== "srgb") t.push('cm = "' + d.cm + '"');
            if (d.icc) t.push('icc = "' + d.icc + '"');
            if (d.cm === "hdr" || d.cm === "hdredid") {
                if (Number(d.sdrbrightness) !== 1) t.push("sdrbrightness = " + fmtNum(d.sdrbrightness));
                if (Number(d.sdrsaturation) !== 1) t.push("sdrsaturation = " + fmtNum(d.sdrsaturation));
            }
            rows.push(t);
        }

        // Align the columns like nwg-displays does
        const widths = [];
        for (const t of rows)
            for (let i = 0; i < t.length; i++)
                widths[i] = Math.max(widths[i] ? widths[i] : 0, t[i].length);

        const lines = [];
        for (const t of rows) {
            const parts = [];
            for (let i = 0; i < t.length; i++) {
                if (i === t.length - 1) parts.push(t[i]);
                else parts.push(t[i] + "," + " ".repeat(Math.max(1, widths[i] - t[i].length + 1)));
            }
            lines.push("hl.monitor({ " + parts.join("") + " })");
        }

        const header = "-- Managed by Quickshell display settings — manual edits will be overwritten on Apply (check these in the settings app)";
        return header + "\n\n" + lines.join("\n") + "\n";
    }

    // ── Validation ──
    function cleanly(px, scale) {
        const v = px / scale;
        return Math.abs(v - Math.round(v)) < 0.000001;
    }

    function validateScale(name) {
        const d = desired[name];
        if (!d || d.disabled === true) return "";
        const m = monitorFor(name);
        const r = modeRes(d.mode);
        const w = r ? r.w : (m ? m.width : 0);
        const h = r ? r.h : (m ? m.height : 0);
        const s = Number(d.scale) > 0 ? Number(d.scale) : 1;
        if (w > 0 && (!cleanly(w, s) || !cleanly(h, s)))
            return "Scale " + fmtNum(s) + " leaves fractional pixels — valid scales divide the resolution cleanly (use 1, 1.25, 1.5, 2…)";
        return "";
    }

    function parsePosition(pos) {
        if (!pos) return null;
        const s = String(pos);
        if (s.indexOf("auto") === 0) return null;
        const p = s.split("x");
        if (p.length !== 2) return null;
        const x = parseInt(p[0]);
        const y = parseInt(p[1]);
        if (!isFinite(x) || !isFinite(y)) return null;
        return { x: x, y: y };
    }

    // Logical size of a monitor with its desired mode / scale / rotation
    function logicalSize(d, m) {
        const r = modeRes(d.mode);
        let w = r ? r.w : (m ? m.width : 0);
        let h = r ? r.h : (m ? m.height : 0);
        const s = Number(d.scale) > 0 ? Number(d.scale) : 1;
        let lw = w / s;
        let lh = h / s;
        const t = Number(d.transform) ? Number(d.transform) : 0;
        if (t % 4 === 1 || t % 4 === 3) { const tmp = lw; lw = lh; lh = tmp; }
        return { w: lw, h: lh };
    }

    function rectOf(name) {
        const d = desired[name];
        if (!d || d.disabled === true) return null;
        const pos = parsePosition(d.position);
        if (!pos) return null;
        const size = logicalSize(d, monitorFor(name));
        if (size.w <= 0 || size.h <= 0) return null;
        return { x: pos.x, y: pos.y, w: size.w, h: size.h };
    }

    function overlaps(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    function validateOverlap(name) {
        const a = rectOf(name);
        if (!a) return "";
        for (const m of monitors) {
            const other = m.name;
            if (other === name) continue;
            const b = rectOf(other);
            if (!b) continue;
            if (overlaps(a, b)) return name + " and " + other + " overlap — adjust position";
        }
        return "";
    }

    // ── Helpers for the drag editor in the arrangement diagram ──
    // Pure: they read the live state and never write anything.

    // Logical size of a monitor as it is right now, rotation included
    function liveSize(m) {
        const s = Number(m.scale) > 0 ? Number(m.scale) : 1;
        let w = Number(m.width) / s;
        let h = Number(m.height) / s;
        const t = Number(m.transform) ? Number(m.transform) : 0;
        if (t % 4 === 1 || t % 4 === 3) { const tmp = w; w = h; h = tmp; }
        return { w: w, h: h };
    }

    // Would `name` at logical x, y sit on top of a monitor that is on screen now?
    // Returns the other monitor's name, or "" when the spot is free.
    function overlapsAt(name, x, y) {
        const m = monitorFor(name);
        if (!m) return "";
        const size = liveSize(m);
        const a = { x: x, y: y, w: size.w, h: size.h };
        for (const other of monitors) {
            if (other.name === name || other.disabled === true) continue;
            const s = liveSize(other);
            if (overlaps(a, { x: other.x, y: other.y, w: s.w, h: s.h })) return other.name;
        }
        return "";
    }

    function validate(name) {
        const scale = validateScale(name);
        if (scale !== "") return scale;
        return validateOverlap(name);
    }

    function liveEnabledCount() {
        let enabled = 0;
        for (const m of monitors) {
            const d = desired[m.name];
            if (!d || d.disabled !== true) enabled++;
        }
        return enabled;
    }

    function validateAll() {
        if (liveEnabledCount() === 0) return "You can't disable the only monitor";
        for (const m of monitors) {
            const problem = validate(m.name);
            if (problem !== "") return problem;
        }
        return "";
    }

    // ── Apply / revert / keep ──
    function snapshot() {
        lastGood = {
            desired: clone(desired),
            text: luaFile.loaded ? luaFile.text() : null
        };
    }

    // Starts (or restarts) the countdown. The snapshot is taken before the file is
    // overwritten, so Revert puts the old file back verbatim.
    function beginChange() {
        if (!pending) {
            if (lastGood === null) snapshot();
            pending = true;
        }
        revertIn = revertSeconds;
        revertTimer.restart();
    }

    // risky = the change can blank the screen (mode, scale, position, transform, mirror, disabled).
    // Returns "" or a problem string; on a problem nothing is written and no countdown starts.
    function apply(risky) {
        const problem = validateAll();
        if (problem !== "") return problem;
        if (risky === true) beginChange();
        writeText(buildLua());
        awaiting = true;
        return "";
    }

    function tick() {
        if (!pending) { revertTimer.stop(); return; }
        revertIn = revertIn - 1;
        if (revertIn <= 0) revert();
    }

    function revert() {
        if (lastGood === null) {
            pending = false;
            revertTimer.stop();
            return;
        }
        const good = clone(lastGood.desired);
        const text = lastGood.text;
        lastGood = null;
        pending = false;
        revertIn = 0;
        revertTimer.stop();
        desired = good;
        if (text !== null && text !== undefined) writeText(text);
        else writeText(buildLua());
        awaiting = true;
        reverted();
    }

    function keep() {
        pending = false;
        revertIn = 0;
        revertTimer.stop();
        lastGood = null;
        synced = true;
    }

    // Does the live state match what we wrote? (auto positions are resolved by Hyprland,
    // so those are not compared)
    function checkSynced() {
        let ok = true;
        for (const m of monitors) {
            const n = m.name;
            const d = desired[n];
            if (!d) { ok = false; continue; }
            if ((d.disabled === true) !== (m.disabled === true)) { ok = false; continue; }
            if (d.disabled === true) continue;

            const mode = String(d.mode);
            if (mode !== "preferred" && mode !== "highres" && mode !== "highrr" && mode !== "maxwidth") {
                const r = modeRes(mode);
                if (r && (r.w !== m.width || r.h !== m.height)) { ok = false; continue; }
                const rate = Number(modeRate(mode));
                if (isFinite(rate) && rate > 0 && Math.abs(rate - m.refreshRate) > 0.6) { ok = false; continue; }
            }
            if (Math.abs(Number(d.scale) - Number(m.scale)) > 0.001) { ok = false; continue; }
            if (Math.round(Number(d.transform)) !== Math.round(Number(m.transform))) { ok = false; continue; }
            if ((Number(d.vrr) > 0 ? 1 : 0) !== (m.vrr ? 1 : 0)) { ok = false; continue; }
            const dm = d.mirror ? d.mirror : "none";
            const mm = m.mirrorOf ? m.mirrorOf : "none";
            if (dm !== mm) { ok = false; continue; }
            const pos = String(d.position);
            if (pos.indexOf("auto") !== 0 && pos !== String(m.x) + "x" + String(m.y)) { ok = false; continue; }
        }
        synced = ok;
    }

    // ── DPMS (session only, not written to the file) ──
    Process {
        id: dpms
        onExited: writeTimer.restart()
    }

    function setDpms(name, on) {
        if (!name) return;
        dpms.command = ["hyprctl", "dispatch", "dpms", on ? "on" : "off", name];
        dpms.running = true;
    }

    // ── Identify ──
    function identify(name) {
        if (name) identifyRequested(name);
    }

    Connections {
        target: Quickshell
        function onScreensChanged() { root.refresh(); }
    }
}

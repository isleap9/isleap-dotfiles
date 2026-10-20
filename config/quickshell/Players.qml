pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Media players (MPRIS) and audio outputs, shared by the dashboard.
Singleton {
    id: root

    // Skip the playerctld proxy, which duplicates the real players
    readonly property var list: Mpris.players.values.filter(p => !p.dbusName?.includes("playerctld"))
    // Picked in the dashboard; otherwise the one playing, otherwise the first
    property string chosen: ""
    readonly property MprisPlayer active: list.find(p => p.dbusName === chosen)
        ?? list.find(p => p.isPlaying) ?? list[0] ?? null

    readonly property bool hasTrack: active !== null && (active.trackTitle ?? "") !== ""

    // Position doesn't update by itself; poll it while something plays
    Timer {
        interval: 1000
        repeat: true
        running: root.active?.isPlaying ?? false
        onTriggered: root.active?.positionChanged()
    }

    function time(s) {
        if (!isFinite(s) || s < 0) s = 0;
        const m = Math.floor(s / 60), sec = Math.floor(s % 60);
        return `${m}:${String(sec).padStart(2, "0")}`;
    }

    function playerIcon(p) {
        const id = (p?.identity ?? "").toLowerCase();
        if (id.includes("spotify")) return "music_note";
        if (id.includes("firefox")) return "public";
        if (id.includes("chrom")) return "public";
        if (id.includes("mpv") || id.includes("vlc")) return "movie";
        return "music_note";
    }

    // ── Audio outputs (PipeWire) ──
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    function sinkName(n) {
        return n?.description || n?.nickname || n?.name || "Output";
    }
    function setSink(n) { Pipewire.preferredDefaultAudioSink = n; }
}

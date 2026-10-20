import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs
import qs.components

// Now playing (like the Waybar mpris module). Click: play/pause, scroll: next/prev.
Pill {
    id: root

    property int maxTextWidth: 420

    // Prefer a playing player; skip the playerctld proxy
    readonly property var players: Mpris.players.values.filter(p => !p.dbusName?.includes("playerctld"))
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property string playerIcon: {
        const id = (player?.identity ?? "").toLowerCase();
        if (id.includes("spotify")) return "\uf1bc";
        if (id.includes("mpv")) return "\uf03d";
        return "\uf001";
    }

    shown: Config.bar.modules.media && player !== null && (player.trackTitle ?? "") !== ""
    onClicked: m => {
        if (m.button === Qt.RightButton) player?.next();
        else player?.togglePlaying();
    }
    onScrolled: w => w.angleDelta.y > 0 ? player?.previous() : player?.next()

    BarText {
        icon: true
        text: root.playerIcon + "  " + (root.player?.isPlaying ? "▶" : "⏸")
    }

    BarText {
        Layout.maximumWidth: root.maxTextWidth
        elide: Text.ElideRight
        font.italic: root.player?.isPlaying ?? false
        text: {
            const artist = root.player?.trackArtist ?? "";
            const title = root.player?.trackTitle ?? "";
            return artist ? `${artist} - ${title}` : title;
        }
    }
}

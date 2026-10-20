pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon (replaces swaync).
// `list` holds everything shown in the notification center.
// `popups` holds the ones currently shown as popups in the corner.
Singleton {
    id: root

    property bool dnd: false
    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length
    property var popups: []
    // Apps whose popups replace each other instead of stacking
    readonly property var latestOnly: ["Spotify"]

    // When each notification arrived (by id), for "Just now" / "5m ago"
    property var arrived: ({})
    property real now: Date.now()
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }

    function timeAgo(n) {
        const t = n ? root.arrived[n.id] : undefined;
        if (!t) return "";
        const s = Math.max(0, (root.now - t) / 1000);
        if (s < 60) return "Just now";
        if (s < 3600) return Math.floor(s / 60) + "m ago";
        if (s < 86400) return Math.floor(s / 3600) + "h ago";
        return Math.floor(s / 86400) + "d ago";
    }

    function removePopup(n) {
        popups = popups.filter(p => p !== n);
    }

    function clearAll() {
        // Copy first: dismissing changes the list we are walking
        for (const n of [...list])
            n.dismiss();
        popups = [];
    }

    function iconFor(n) {
        if (!n) return "";
        if (n.image) return n.image;
        const icon = n.appIcon;
        if (!icon) return "";
        if (icon.startsWith("/") ) return "file://" + icon;
        if (icon.startsWith("file://") || icon.startsWith("image://")) return icon;
        return Quickshell.iconPath(icon, true);
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            root.now = Date.now();
            root.arrived[n.id] = root.now;
            n.closed.connect(() => root.removePopup(n));
            if (!root.dnd || n.urgency === NotificationUrgency.Critical) {
                // A popup identical to one already showing replaces it; music apps keep only
                // their newest popup (the song that's playing now)
                const replaces = p => p.appName === n.appName
                    && (root.latestOnly.includes(n.appName) || (p.summary === n.summary && p.body === n.body));
                root.popups = [n, ...root.popups.filter(p => !replaces(p))];
            }
        }
    }
}

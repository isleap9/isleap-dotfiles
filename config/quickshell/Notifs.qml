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

pragma Singleton

import QtQuick
import Quickshell

// Shared open/close animation styles (Settings → Animations).
// A panel animates a progress value p from 0 (hidden) to 1 (open); these turn p into
// opacity / scale / offset for the chosen style.
Singleton {
    readonly property var styles: [["slide", "Slide"], ["bounce", "Bounce"], ["scale", "Scale"], ["fade", "Fade"], ["none", "None"]]

    // Material 3 "emphasized decelerate"
    readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]

    function openMs(style) {
        const t = Theme.animMs;
        switch (style) {
        case "none": return 0;
        case "fade": return Math.round(t * 0.8);
        case "scale": return Math.round(t * 1.1);
        default: return Math.round(t * 1.3);        // slide, bounce
        }
    }
    function closeMs(style) {
        return Config.animations.closing && style !== "none" ? Math.round(Theme.animMs * 0.6) : 0;
    }

    function opacity(style, p) {
        if (style === "none") return p > 0 ? 1 : 0;
        if (style === "bounce") return Math.max(0, Math.min(1, p * 2.5));
        if (style === "fade") return Math.max(0, Math.min(1, p));
        return Math.max(0, Math.min(1, p * 1.4));
    }
    function scale(style, p) {
        if (style === "scale") return 0.88 + 0.12 * p;
        if (style === "bounce") return 0.82 + 0.18 * p;
        return 1;
    }
    // dist: how far the panel travels (signed: negative = comes from above / the left)
    function offset(style, p, dist) {
        if (style === "slide") return (1 - p) * dist;
        if (style === "bounce") return (1 - p) * Math.sign(dist || -1) * Math.min(28, Math.abs(dist || 28));
        return 0;
    }
}

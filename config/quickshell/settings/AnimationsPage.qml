import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

// How every panel opens and closes. Styles live in Motion.qml.
Page {
    id: page

    readonly property var panels: [
        { key: "popups",        label: "Notification popups", description: "Bounce drops in from above; Slide comes in from the screen edge" },
        { key: "notifCenter",   label: "Notification center", description: "SUPER+N" },
        { key: "dashboard",     label: "Dashboard",           description: "Slide comes out from under the bar" },
        { key: "quickSettings", label: "Quick settings",      description: "SUPER+X, volume / network in the bar" },
        { key: "trayMenu",      label: "Tray menus",          description: "Clicking an icon in the system tray" },
        { key: "launcher",      label: "App launcher",        description: "SUPER+SPACE" },
        { key: "controlCenter", label: "Control center",      description: "SUPER+ALT+SPACE, clipboard, emoji, capture…" },
        { key: "powerMenu",     label: "Power menu",          description: "SUPER+P" },
        { key: "overview",      label: "Workspace overview",  description: "SUPER+TAB" },
        { key: "osd",           label: "Volume / caps lock popup", description: "On-screen display" }
    ]
    readonly property var allSame: {
        const first = Config.animations[panels[0].key];
        return panels.every(p => Config.animations[p.key] === first) ? first : "";
    }

    Section {
        title: "General"
        description: "Slide · Bounce (soft overshoot) · Scale (Material grow) · Fade · None"
        Option {
            label: "Speed"
            description: "For every animation in the shell"
            Segmented {
                options: [[0, "Off"], [0.5, "Fast"], [1, "Normal"], [2, "Slow"]]
                current: Config.appearance.animationSpeed
                onSelected: v => Config.appearance.animationSpeed = v
            }
        }
        Option {
            label: "Animate closing"
            description: Config.animations.closing ? "Panels play their animation in reverse when they close" : "Panels disappear right away"
            MSwitch { checked: Config.animations.closing; onToggled: Config.animations.closing = !checked }
        }
        Option {
            label: "Use one style everywhere"
            description: page.allSame === "" ? "Panels currently use different styles" : "Every panel uses the same style"
            Segmented {
                options: Motion.styles
                current: page.allSame
                onSelected: v => { for (const p of page.panels) Config.animations[p.key] = v; }
            }
        }
        Option {
            label: "Reset animations"
            description: "Back to the defaults: Normal speed, closing animations on, and each panel's original style"
            PillButton {
                text: "Reset to default"
                onClicked: {
                    const defaults = {
                        closing: true, popups: "bounce", notifCenter: "slide", dashboard: "slide",
                        quickSettings: "slide", trayMenu: "slide", launcher: "scale",
                        controlCenter: "scale", powerMenu: "fade", overview: "scale", osd: "scale"
                    };
                    for (const k in defaults) Config.animations[k] = defaults[k];
                    Config.appearance.animationSpeed = 1.0;
                }
            }
        }
    }

    Section {
        title: "Per panel"
        description: "Pick and choose"

        Repeater {
            model: page.panels
            Option {
                id: opt
                required property var modelData
                label: modelData.label
                description: modelData.description
                Segmented {
                    options: Motion.styles
                    current: Config.animations[opt.modelData.key]
                    onSelected: v => Config.animations[opt.modelData.key] = v
                }
            }
        }

        Option {
            label: "Try the popup animation"
            PillButton {
                text: "Send a test notification"
                onClicked: Quickshell.execDetached(["notify-send", "-a", "Settings", "Animation preview", "This is how popups look now"])
            }
        }
    }
}

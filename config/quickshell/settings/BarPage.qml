import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Page {
    id: page

    Section {
        title: "Bar"
        description: "Your four Waybar layouts are kept exactly as imported. Custom is your own bar — the only one you can edit."
        Option {
            icon: "toolbar"
            label: "Show"
            description: ({
                default: "Waybar: separate pills, with cava",
                default2: "Waybar: grouped right side, classic workspaces",
                minimal: "Waybar: everything in one centered pill",
                sleek: "Waybar: solid bar attached to the top edge",
                custom: "Your own bar — edit it below"
            })[BarConfig.layout] ?? ""
            Segmented {
                options: [["default", "Default"], ["default2", "Default 2"], ["minimal", "Minimal"], ["sleek", "Sleek"], ["custom", "Custom"]]
                current: BarConfig.layout
                onSelected: v => BarConfig.set(v)
            }
        }
    }

    // ── Waybar layout selected: nothing to edit ──
    Section {
        visible: !BarConfig.isCustom
        title: "Custom bar"
        Option {
            icon: "edit"
            label: "Want to build your own?"
            description: "Switch to Custom to add, remove and arrange widgets, and choose top/bottom and floating/solid."
            PillButton { text: "Edit Custom bar"; primary: true; onClicked: BarConfig.set("custom") }
        }
    }

    // ── Custom bar editor ──
    Section {
        visible: BarConfig.isCustom
        title: "Custom bar — look"
        Option {
            label: "Position"
            Segmented {
                options: [["top", "Top"], ["bottom", "Bottom"]]
                current: Config.bar.position
                onSelected: v => Config.bar.position = v
            }
        }
        Option {
            label: "Style"
            description: ({
                pills: "Each widget floats in its own pill",
                floatingBar: "One bar floating away from the screen edge",
                attached: "One bar attached to the screen edge"
            })[BarConfig.customStyle]
            Segmented {
                options: [["pills", "Pills"], ["floatingBar", "Floating bar"], ["attached", "Attached bar"]]
                current: BarConfig.customStyle
                onSelected: v => BarConfig.setCustomStyle(v)
            }
        }

        // Floating bar / attached bar
        Option {
            visible: BarConfig.customStyle === "floatingBar"
            label: "Gap from the screen edge"
            Stepper { value: BarConfig.customLook.solidGap ?? 0; from: 1; to: 60; suffix: " px"; onChanged: v => BarConfig.setLook("solidGap", v) }
        }
        Option {
            visible: BarConfig.customSolid
            label: "Width"
            Segmented {
                options: [["fit", "Fit the widgets"], ["full", "Full width"]]
                current: BarConfig.customLook.solidWidth ?? "fit"
                onSelected: v => BarConfig.setLook("solidWidth", v)
            }
        }
        Option {
            visible: BarConfig.customSolid
            label: "Corner radius"
            Stepper { value: BarConfig.customLook.barRadius ?? 10; from: 0; to: 30; suffix: " px"; onChanged: v => BarConfig.setLook("barRadius", v) }
        }
        Option {
            id: cornersOption
            visible: BarConfig.customStyle === "attached"
            readonly property bool attached: (BarConfig.customLook.solidGap ?? 0) === 0
            label: "Outer corners"
            description: "Curved corners that blend the bar into the screen edge"
            Toggle {
                checked: BarConfig.customLook.outerCorners === true
                onToggled: BarConfig.setLook("outerCorners", !checked)
            }
        }

        // Floating pills
        Option {
            visible: !BarConfig.customSolid
            label: "Pill roundness"
            description: "100% = fully round ends, 0% = square"
            Stepper { value: BarConfig.customLook.roundness ?? 100; from: 0; to: 100; step: 10; suffix: "%"; onChanged: v => BarConfig.setLook("roundness", v) }
        }

        Option {
            label: "Widget bubbles"
            description: "Each widget in a tonal bubble (one-piece bar or shared pills). Use a widget's ⚙ → \"Share a bubble with the next widget\" to group them."
            MSwitch { checked: BarConfig.customLook.bubbles ?? true; onToggled: BarConfig.setLook("bubbles", !checked) }
        }
        Option {
            label: "Density"
            description: "Padding inside pills, and between widgets on a one-piece bar"
            Segmented {
                options: [["compact", "Compact"], ["default", "Default"], ["comfortable", "Comfortable"]]
                current: BarConfig.customLook.density ?? "default"
                onSelected: v => BarConfig.setLook("density", v)
            }
        }
    }

    Section {
        visible: BarConfig.isCustom
        title: "Custom bar — colors"
        description: "Theme colors follow the theme switcher. Each widget can override these under ⚙."
        Option {
            label: "Background"
            description: BarConfig.customSolid ? "The bar (auto: darkest theme color)" : "The pills (auto: theme pill color)"
            ColorChoice { value: BarConfig.customLook.background ?? ""; onSelected: v => BarConfig.setLook("background", v) }
        }
        Option {
            label: "Background opacity"
            description: "0% = see-through"
            Stepper { value: BarConfig.customLook.opacity ?? 100; from: 0; to: 100; step: 5; suffix: "%"; onChanged: v => BarConfig.setLook("opacity", v) }
        }
        Option {
            label: "Border"
            Stepper { value: BarConfig.customLook.borderWidth ?? 0; from: 0; to: 6; suffix: " px"; onChanged: v => BarConfig.setLook("borderWidth", v) }
        }
        Option {
            visible: (BarConfig.customLook.borderWidth ?? 0) > 0
            label: "Border color"
            ColorChoice { value: BarConfig.customLook.borderColor ?? "accent"; onSelected: v => BarConfig.setLook("borderColor", v) }
        }
        Option {
            label: "Text"
            ColorChoice { value: BarConfig.customLook.textColor ?? "fg1"; onSelected: v => BarConfig.setLook("textColor", v) }
        }
        Option {
            label: "Icons"
            ColorChoice { value: BarConfig.customLook.iconColor ?? "fg1"; onSelected: v => BarConfig.setLook("iconColor", v) }
        }
        Option {
            label: "Accent"
            description: "Active workspace"
            ColorChoice { value: BarConfig.customLook.accentColor ?? "accent"; onSelected: v => BarConfig.setLook("accentColor", v) }
        }
    }

    Section {
        visible: BarConfig.isCustom
        title: "Custom bar — text and icons"
        Option {
            label: "Text size"
            description: (BarConfig.customLook.textSize ?? 0) > 0 ? "" : "Same as the app font size (Appearance)"
            Stepper { value: BarConfig.textSize; from: 9; to: 30; suffix: " px"; onChanged: v => BarConfig.setLook("textSize", v) }
        }
        Option {
            label: "Icon size"
            description: (BarConfig.customLook.iconSize ?? 0) > 0 ? "" : "Text size + 3"
            Stepper { value: BarConfig.iconSize; from: 9; to: 40; suffix: " px"; onChanged: v => BarConfig.setLook("iconSize", v) }
        }
        Option {
            label: "Text weight"
            Segmented {
                options: [["regular", "Regular"], ["bold", "Bold"], ["black", "Black"]]
                current: BarConfig.customLook.textWeight ?? "black"
                onSelected: v => BarConfig.setLook("textWeight", v)
            }
        }
        Option {
            id: resetLook
            property bool pending: false
            icon: "settings_backup_restore"
            label: "Reset the look"
            description: pending ? "Click again to reset colors, sizes and shape" : "Colors, sizes and shape back to the defaults. Widgets stay as they are."
            PillButton {
                text: resetLook.pending ? "Confirm reset" : "Reset"
                onClicked: {
                    if (resetLook.pending) { BarConfig.resetLook(); resetLook.pending = false; }
                    else { resetLook.pending = true; lookTimer.restart(); }
                }
            }
            Timer { id: lookTimer; interval: 4000; onTriggered: resetLook.pending = false }
        }
    }

    Section {
        visible: BarConfig.isCustom
        title: "Custom bar — widgets"
        description: "Use the arrows to reorder or move a widget to another lane, the gear for its options, and × to remove it. Changes show on the bar right away."

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            spacing: 8

            LaneEditor { lane: "left"; title: "Left" }
            LaneEditor { lane: "center"; title: "Center" }
            LaneEditor { lane: "right"; title: "Right" }
        }
    }

    Section {
        id: startOver
        visible: BarConfig.isCustom
        title: "Custom bar — start over"
        property string pending: ""   // layout clicked once, waiting for a second click

        Option {
            icon: "settings_backup_restore"
            label: "Replace the Custom bar with a copy of a Waybar layout"
            description: startOver.pending !== ""
                ? "Click it again to replace your Custom widgets"
                : "Your Custom widgets are replaced. The Waybar layouts themselves never change."
            Segmented {
                options: [["default", "Default"], ["default2", "Default 2"], ["minimal", "Minimal"], ["sleek", "Sleek"]]
                current: startOver.pending
                onSelected: v => {
                    if (startOver.pending === v) {
                        BarConfig.resetCustom(v);
                        startOver.pending = "";
                    } else {
                        startOver.pending = v;
                        confirmTimer.restart();
                    }
                }
            }
        }
        Timer { id: confirmTimer; interval: 4000; onTriggered: startOver.pending = "" }
    }

    // ── Shared by every bar ──
    Section {
        title: "Size and spacing"
        description: "For every bar, Waybar layouts included"
        Option {
            label: "Height"
            Stepper { value: Config.bar.height; from: 28; to: 60; suffix: " px"; onChanged: v => Config.bar.height = v }
        }
        Option {
            label: "Gap from the screen edge"
            description: "Pills style and the floating Waybar layouts"
            Stepper { value: Config.bar.topMargin; from: 0; to: 40; suffix: " px"; onChanged: v => Config.bar.topMargin = v }
        }
        Option {
            label: "Gap from the screen sides"
            Stepper { value: Config.bar.sideMargin; from: 0; to: 120; step: 2; suffix: " px"; onChanged: v => Config.bar.sideMargin = v }
        }
        Option {
            label: "Space between widgets"
            Stepper { value: Config.bar.spacing; from: 0; to: 40; step: 2; suffix: " px"; onChanged: v => Config.bar.spacing = v }
        }
    }

    Section {
        title: "Clock and weather"
        Option {
            label: "24-hour clock"
            description: "For every clock on every bar"
            Toggle { checked: Config.bar.clock24h; onToggled: Config.bar.clock24h = !checked }
        }
        Option {
            label: "Weather city"
            description: "Any city name wttr.in understands"
            TextBox { text: Config.bar.weatherCity; placeholder: "e.g. Bari"; onAccepted: v => Config.bar.weatherCity = v.trim() }
        }
    }

    Section {
        title: "Workspaces"
        Option {
            label: "Always show at least"
            description: "Workspaces past this number appear when used"
            Stepper { value: Config.bar.minWorkspaces; from: 1; to: 10; onChanged: v => Config.bar.minWorkspaces = v }
        }
    }
}

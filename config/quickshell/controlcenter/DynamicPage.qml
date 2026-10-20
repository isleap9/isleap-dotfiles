import QtQuick
import qs

// Dynamic (wallpaper-based) theme settings — logic lives in DynamicTheme.qml
MenuList {
    id: root

    property var cc   // set by the loader
    property bool pickingScheme: false

    placeholder: pickingScheme ? "Search schemes…" : "Search…"
    items: pickingScheme
        ? DynamicTheme.schemes.map(([id, desc]) => ({ icon: "auto_awesome", label: id, sub: desc, scheme: id, checked: id === DynamicTheme.scheme }))
        : [
            { icon: DynamicTheme.enabled ? "toggle_on" : "toggle_off",
              label: DynamicTheme.enabled ? "Dynamic theme is ON" : "Dynamic theme is OFF",
              sub: DynamicTheme.enabled ? "Click to turn off" : "Click to turn on — then pick a wallpaper",
              id: "toggle", checked: DynamicTheme.enabled },
            { icon: "contrast", label: "Apply to current wallpaper", sub: "Regenerate colors now", id: "apply" },
            { icon: "auto_awesome", label: "Scheme type", sub: DynamicTheme.scheme, id: "scheme" },
            { icon: DynamicTheme.mode === "dark" ? "clear_night" : "light_mode", label: "Mode: " + DynamicTheme.mode,
              sub: "Switch to " + (DynamicTheme.mode === "dark" ? "light" : "dark"), id: "mode" }
        ]

    onActivated: item => {
        if (pickingScheme) {
            DynamicTheme.setScheme(item.scheme);
            pickingScheme = false;
            query = "";
            return;
        }
        switch (item.id) {
        case "toggle": DynamicTheme.setEnabled(!DynamicTheme.enabled); break;
        case "apply": DynamicTheme.applyNow(); break;
        case "scheme":
            pickingScheme = true;
            query = "";
            currentIndex = DynamicTheme.schemes.findIndex(s => s[0] === DynamicTheme.scheme);
            break;
        case "mode": DynamicTheme.setMode(DynamicTheme.mode === "dark" ? "light" : "dark"); break;
        }
    }
    onBack: {
        if (pickingScheme) { pickingScheme = false; query = ""; }
        else cc?.go("main");
    }

    Component.onCompleted: DynamicTheme.refresh()
}

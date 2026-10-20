pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The theme switcher's themes (from ~/.config/waybar/scripts/theme-switcher.sh), with swatch colors.
// Used by the control center and the Settings app.
Singleton {
    id: root

    readonly property string switcher: Quickshell.env("HOME") + "/.config/waybar/scripts/theme-switcher.sh"
    property var list: []          // [{ key, name, file, colors: [bg1, fg1, accent, red, green, blue] }]
    property string current: ""    // active theme css file, e.g. "onedark.css" (dynamic.css = wallpaper colors)

    function apply(key) {
        current = list.find(t => t.key === key)?.file ?? current;
        Quickshell.execDetached([switcher, key]);
    }

    function refresh() {
        listProc.running = true;
    }

    Process {
        id: listProc
        running: true
        command: ["sh", "-c", `
            "$0" --list > "\${XDG_RUNTIME_DIR:-/tmp}/qs-themes.list" || exit
            cd "$HOME/.config/waybar/themes" || exit
            echo "ACTIVE	$(basename "$(readlink active.css)")"
            while IFS='	' read -r key file; do
                printf '%s\\t%s' "$key" "$file"
                for c in bg1 fg1 accent red green blue; do
                    printf '\\t%s' "$(grep -oP "@define-color\\s+$c\\s+\\K#[0-9a-fA-F]+" "$file" | head -1)"
                done
                echo
            done < "\${XDG_RUNTIME_DIR:-/tmp}/qs-themes.list"`, root.switcher]
        stdout: StdioCollector {
            onStreamFinished: {
                const themes = [];
                for (const line of text.split("\n")) {
                    const p = line.split("\t");
                    if (p[0] === "ACTIVE") root.current = p[1];
                    else if (p.length >= 2) themes.push({ key: p[0], name: p[0].trim(), file: p[1], colors: p.slice(2).filter(c => c) });
                }
                root.list = themes;
            }
        }
    }
}

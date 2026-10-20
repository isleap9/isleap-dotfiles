#!/usr/bin/env bash
# Apply a KDE color scheme without Plasma (replaces plasma-apply-colorscheme).
# Copies the scheme's color groups into ~/.config/kdeglobals and tells running
# Qt/KDE apps to reload their palette. Needs plasma-integration for Qt apps to
# read kdeglobals (QT_QPA_PLATFORMTHEME=kde).
# Usage: apply-kde-colors.sh <SchemeName | /path/to/scheme.colors>
set -euo pipefail

ARG="${1:-}"
if [[ -z "$ARG" ]]; then
    echo "Usage: apply-kde-colors.sh <SchemeName | /path/to/scheme.colors>" >&2
    exit 1
fi

if [[ -f "$ARG" ]]; then
    SCHEME_FILE="$ARG"
else
    SCHEME_FILE=""
    for dir in "$HOME/.local/share/color-schemes" /usr/share/color-schemes; do
        if [[ -f "$dir/$ARG.colors" ]]; then
            SCHEME_FILE="$dir/$ARG.colors"
            break
        fi
    done
    if [[ -z "$SCHEME_FILE" ]]; then
        echo "Color scheme not found: $ARG" >&2
        exit 1
    fi
fi

python3 - "$SCHEME_FILE" "$HOME/.config/kdeglobals" <<'EOF'
import os, re, sys

scheme_path, globals_path = sys.argv[1], sys.argv[2]

def parse(path):
    """Read an INI file into an ordered list of (section, [lines])."""
    sections, current = [], None
    if not os.path.exists(path):
        return sections
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("["):
            current = (line.strip(), [])
            sections.append(current)
        elif current is not None and line.strip():
            current[1].append(line)
    return sections

scheme = parse(scheme_path)
existing = parse(globals_path)

# The scheme's display name, falling back to the file name.
name = os.path.splitext(os.path.basename(scheme_path))[0]
for sec, lines in scheme:
    if sec in ("[General]", "[ColorScheme]"):
        for l in lines:
            if l.startswith("Name="):
                name = l.split("=", 1)[1]

# Sections the scheme owns: every color group plus [WM]. Drop old copies so a
# previous scheme's groups don't linger.
def owned(sec):
    return sec.startswith("[Colors:") or sec == "[WM]"

out = [(s, l) for s, l in existing if not owned(s)]
for sec, lines in scheme:
    if owned(sec):
        out.append((sec, lines))

# Merge [General] and [KDE] keys from the scheme into kdeglobals.
def merge(section, new_lines):
    for i, (s, lines) in enumerate(out):
        if s == section:
            keys = {l.split("=", 1)[0]: l for l in lines if "=" in l}
            for l in new_lines:
                if "=" in l:
                    keys[l.split("=", 1)[0]] = l
            out[i] = (s, list(keys.values()))
            return
    out.append((section, new_lines))

for sec, lines in scheme:
    if sec in ("[General]", "[KDE]"):
        merge(sec, [l for l in lines if not l.startswith("Name=")])
merge("[General]", [f"ColorScheme={name}"])

# Matugen writes rgb(r, g, b); KDE wants r,g,b.
rgb = re.compile(r"rgb\((\d+),\s*(\d+),\s*(\d+)\)")
with open(globals_path, "w", encoding="utf-8") as f:
    for sec, lines in out:
        f.write(sec + "\n")
        for l in lines:
            f.write(rgb.sub(r"\1,\2,\3", l) + "\n")
        f.write("\n")
EOF

# Tell running KDE/Qt apps the palette changed (0 = PaletteChanged).
dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true

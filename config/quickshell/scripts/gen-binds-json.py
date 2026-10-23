#!/usr/bin/env python3
"""Generate a cheatsheet JSON from Hyprland's binds.lua.

Usage: gen-binds-json.py [binds.lua]      (default ~/.config/hypr/modules/binds.lua)

Writes ~/.cache/quickshell-binds.json as an array of
    {"combo": "SUPER + T", "description": "Terminal (kitty)", "group": "Apps"}

Atomic: the cache is only replaced after the whole file parsed successfully, so a
half-written or unexpected binds.lua leaves the previous cache (and the control
center cheatsheet) intact. Exits nonzero on any surprising line shape.
"""

import json
import os
import re
import sys

DEFAULT_BINDS = os.path.expanduser("~/.config/hypr/modules/binds.lua")
OUT_PATH = os.path.expanduser("~/.cache/quickshell-binds.json")


class ParseError(Exception):
    pass


# ---------------------------------------------------------------- text helpers

def split_comment(line):
    """Split `code -- comment` without being fooled by `--` inside strings."""
    in_str = False
    esc = False
    i = 0
    while i < len(line) - 1:
        c = line[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == "-" and line[i + 1] == "-":
                return line[:i], line[i + 2:]
        i += 1
    return line, None


def split_top(text, sep):
    """Split on `sep` at paren/brace/bracket depth 0, outside string literals."""
    parts = []
    buf = []
    depth = 0
    in_str = False
    esc = False
    i = 0
    while i < len(text):
        c = text[i]
        if in_str:
            buf.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            buf.append(c)
            i += 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        if depth == 0 and text.startswith(sep, i):
            parts.append("".join(buf))
            buf = []
            i += len(sep)
            continue
        buf.append(c)
        i += 1
    if in_str:
        raise ParseError("unterminated string literal")
    parts.append("".join(buf))
    return parts


def unquote(lit):
    lit = lit.strip()
    if len(lit) < 2 or not (lit.startswith('"') and lit.endswith('"')):
        raise ParseError("expected a string literal, got: %s" % lit)
    body = lit[1:-1]
    return body.replace('\\"', '"').replace("\\\\", "\\")


def norm_space(text):
    return re.sub(r"\s+", " ", text).strip()


# ------------------------------------------------------------- combo handling

MOUSE_COMBOS = {
    "mouse:272": "LMB drag",
    "mouse:273": "RMB drag",
    "mouse_down": "Scroll down",
    "mouse_up": "Scroll up",
}


def build_combo(expr, main_mod, i_val):
    """Evaluate a Lua concatenation of literals / mainMod / i into display text."""
    pieces = []
    for part in split_top(expr, ".."):
        part = part.strip()
        if not part:
            raise ParseError("empty concatenation segment in combo: %r" % expr)
        if part == "mainMod":
            pieces.append(main_mod)
        elif part in ("i", "tostring(i)"):
            if i_val is None:
                raise ParseError("loop variable used outside a loop: %r" % expr)
            pieces.append(str(i_val))
        elif part.startswith('"'):
            pieces.append(unquote(part))
        else:
            raise ParseError("unsupported combo expression: %r" % part)

    combo = norm_space("".join(pieces))
    combo = re.sub(r"\s*\+\s*", " + ", combo)
    for raw, pretty in MOUSE_COMBOS.items():
        if combo.endswith(" + " + raw):
            combo = combo[: -len(raw)] + pretty
            break
    if not combo:
        raise ParseError("empty combo")
    return combo


# -------------------------------------------------------- description synthesis

IPC_DESCRIPTIONS = {
    "powermenu toggle": "Power menu",
    "files launch": "Files",
    "launcher toggle": "App launcher",
    "dashboard toggle": "Dashboard",
    "quicksettings toggle": "Quick settings",
    "overview toggle": "Workspace overview",
    "notifications toggle": "Notifications",
    "controlcenter open clipboard": "Clipboard history",
    "controlcenter open capture": "Capture menu",
    "controlcenter open themes": "Theme switcher",
    "controlcenter open emoji": "Emoji picker",
    "controlcenter toggle": "Control center",
    "settings toggle": "Settings",
    "brightness raise": "Brightness up",
    "brightness lower": "Brightness down",
}

COMMAND_DESCRIPTIONS = {
    "kitty": "Terminal (kitty)",
    "google-chrome-stable": "Browser (Chrome)",
    "code": "VS Code",
    "dolphin": "File manager (Dolphin)",
    "discord": "Discord",
    "spotify": "Spotify",
    "loginctl lock-session": "Lock screen",
    "playerctl next": "Next track",
    "playerctl previous": "Previous track",
    "playerctl play-pause": "Play / pause",
    "hyprshot": "Screenshot region",
    "launch.sh": "Restart Quickshell",
    "wallpaper-picker.sh": "Wallpaper picker",
    "color-picker.sh": "Color picker",
}

# Trailing comments that read badly in a cheatsheet
COMMENT_OVERRIDES = {
    "kill active": "Close window",
    "quickshell reload": "Restart Quickshell",
    "vscode": "VS Code",
    "locks with qylock (via hypridle)": "Lock screen",
}

# wpctl is used for the XF86 volume keys; name them by intent
WPCI_DESCRIPTIONS = (
    ("set-volume", "5%+", "Volume up"),
    ("set-volume", "5%-", "Volume down"),
    ("set-mute", "@DEFAULT_AUDIO_SINK@", "Mute output"),
    ("set-mute", "@DEFAULT_AUDIO_SOURCE@", "Mute microphone"),
)


def describe_command(cmd):
    cmd = norm_space(cmd)
    if cmd.startswith("qs ipc call "):
        rest = cmd[len("qs ipc call "):].strip()
        if rest in IPC_DESCRIPTIONS:
            return IPC_DESCRIPTIONS[rest]
        words = rest.replace("controlcenter", "control center").split()
        return " ".join(words).capitalize() if words else "Quickshell"

    if cmd.startswith("wpctl "):
        for needle, needle2, desc in WPCI_DESCRIPTIONS:
            if needle in cmd and needle2 in cmd:
                return desc
        return "Volume"

    if cmd in COMMAND_DESCRIPTIONS:
        return COMMAND_DESCRIPTIONS[cmd]

    first = cmd.split()[0] if cmd.split() else ""
    base = os.path.basename(first)
    if base in COMMAND_DESCRIPTIONS:
        return COMMAND_DESCRIPTIONS[base]
    base = re.sub(r"\.(sh|py|bash)$", "", base)
    return norm_space(base.replace("-", " ").replace("_", " ")).capitalize() or "Command"


def workspace_value(expr, i_val):
    expr = expr.strip()
    if expr in ("i", "tostring(i)"):
        if i_val is None:
            raise ParseError("loop variable used outside a loop")
        return str(i_val)
    if expr.startswith('"'):
        return unquote(expr)
    raise ParseError("unsupported workspace expression: %r" % expr)


def describe_action(action, i_val=None):
    a = norm_space(action)

    m = re.match(r'^hl\.dsp\.exec_cmd\("((?:[^"\\]|\\.)*)"\)$', a)
    if m:
        return describe_command(m.group(1).replace('\\"', '"'))

    if re.match(r"^hl\.dsp\.window\.close\(\)$", a):
        return "Close window"
    if re.match(r"^hl\.dsp\.window\.float\(", a):
        return "Toggle floating"
    m = re.match(r"^hl\.dsp\.window\.fullscreen\(\{\s*mode\s*=\s*(\d+)", a)
    if m:
        return {"0": "True fullscreen", "1": "Maximize"}.get(m.group(1), "Fullscreen")
    m = re.match(r'^hl\.dsp\.focus\(\{\s*direction\s*=\s*"(\w+)"', a)
    if m:
        return "Move focus " + m.group(1)
    m = re.match(r"^hl\.dsp\.focus\(\{\s*workspace\s*=\s*(.+?)\s*\}\)$", a)
    if m:
        ws = workspace_value(m.group(1), i_val)
        if ws == "e+1":
            return "Next workspace"
        if ws == "e-1":
            return "Previous workspace"
        return "Switch to workspace " + ws
    m = re.match(r"^hl\.dsp\.window\.move\(\{\s*workspace\s*=\s*(.+?)\s*\}\)$", a)
    if m:
        return "Move window to workspace " + workspace_value(m.group(1), i_val)
    if re.match(r"^hl\.dsp\.workspace\.toggle_special\(", a):
        return "Toggle special workspace"
    if re.match(r"^hl\.dsp\.window\.drag\(\)$", a):
        return "Move window (drag)"
    if re.match(r"^hl\.dsp\.window\.resize\(\)$", a):
        return "Resize window (drag)"

    raise ParseError("unsupported action: %r" % action)


def clean_comment(text):
    text = norm_space(text.replace("\t", " "))
    text = re.sub(r"\s*\(\$[^)]*\)", "", text)   # drop "($menu)"-style hints
    text = text.strip()
    if text.lower() in COMMENT_OVERRIDES:
        return COMMENT_OVERRIDES[text.lower()]
    return text[:1].upper() + text[1:] if text else ""


# --------------------------------------------------------------------- parsing

def parse_bind(code, main_mod, group, i_val=None):
    code = code.strip()
    if not code.startswith("hl.bind(") or not code.endswith(")"):
        raise ParseError("expected an hl.bind(...) call: %r" % code)

    inner = code[len("hl.bind("):-1]
    args = split_top(inner, ",")
    if len(args) not in (2, 3):
        raise ParseError("hl.bind needs 2 or 3 arguments: %r" % code)

    combo = build_combo(args[0], main_mod, i_val)
    action = args[1].strip()
    return combo, action


def parse(path):
    with open(path, "r", encoding="utf-8") as fh:
        lines = fh.read().splitlines()

    main_mod = "SUPER"
    group = "General"
    entries = []
    seen_main_mod = False

    i = 0
    while i < len(lines):
        raw = lines[i]
        code, comment = split_comment(raw)
        stripped = code.strip()

        if not stripped:
            # A group header is a comment line starting in column 0, like "-- Apps".
            if comment is not None and raw[:1] == "-":
                text = norm_space(comment)
                if re.match(r"^[A-Za-z]", text):
                    # Drop trailing parentheticals: they are hints, not group names
                    group = re.sub(r"\s*\([^)]*\)\s*$", "", text) or text
            i += 1
            continue

        m = re.match(r'^local\s+mainMod\s*=\s*"([^"]*)"$', stripped)
        if m:
            main_mod = m.group(1)
            seen_main_mod = True
            i += 1
            continue

        m = re.match(r"^for\s+i\s*=\s*(\d+)\s*,\s*(\d+)\s+do$", stripped)
        if m:
            lo, hi = int(m.group(1)), int(m.group(2))
            if comment is not None and comment.strip():
                raise ParseError("unexpected comment after loop header on line %d" % (i + 1))
            i += 1
            bind_lines = []
            closed = False
            while i < len(lines):
                inner_code, inner_comment = split_comment(lines[i])
                inner = inner_code.strip()
                if inner == "end":
                    closed = True
                    i += 1
                    break
                if not inner:
                    i += 1
                    continue
                if inner.startswith("hl.bind("):
                    bind_lines.append((inner, inner_comment))
                    i += 1
                    continue
                raise ParseError("unsupported line inside loop on line %d: %r" % (i + 1, inner))
            if not closed:
                raise ParseError("unterminated for-loop starting before line %d" % (i + 1))
            if not bind_lines:
                raise ParseError("for-loop contains no hl.bind")
            for n in range(lo, hi + 1):
                for bind_code, bind_comment in bind_lines:
                    combo, action = parse_bind(bind_code, main_mod, group, n)
                    desc = clean_comment(bind_comment) if bind_comment else ""
                    entries.append({
                        "combo": combo,
                        "description": desc or describe_action(action, n),
                        "group": group,
                    })
            continue

        if stripped == "end":
            raise ParseError("stray `end` on line %d" % (i + 1))

        if stripped.startswith("hl.bind("):
            combo, action = parse_bind(stripped, main_mod, group)
            desc = clean_comment(comment) if comment else ""
            entries.append({
                "combo": combo,
                "description": desc or describe_action(action),
                "group": group,
            })
            i += 1
            continue

        raise ParseError("unsupported line %d: %r" % (i + 1, stripped))

    if not seen_main_mod:
        raise ParseError("no `local mainMod = ...` found")
    if not entries:
        raise ParseError("no keybinds found")
    return entries


def main(argv):
    path = argv[1] if len(argv) > 1 else DEFAULT_BINDS
    try:
        entries = parse(path)
    except (ParseError, OSError) as exc:
        print("gen-binds-json: %s" % exc, file=sys.stderr)
        return 1

    out_dir = os.path.dirname(OUT_PATH)
    os.makedirs(out_dir, exist_ok=True)
    # Unique temp name: the settings app and the control center may both run us at once
    tmp = "%s.%d.tmp" % (OUT_PATH, os.getpid())
    try:
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(entries, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        os.replace(tmp, OUT_PATH)
    except OSError as exc:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        print("gen-binds-json: %s" % exc, file=sys.stderr)
        return 1
    print("gen-binds-json: wrote %d entries to %s" % (len(entries), OUT_PATH), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

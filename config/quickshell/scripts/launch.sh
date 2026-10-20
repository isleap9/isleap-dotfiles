#!/usr/bin/env bash
# Start (or restart) the Quickshell desktop. Also stops Waybar and swaync, which it replaces.
# Makes sure only ONE copy runs: two copies mean two bars, two notification servers and
# two programs saving config.json at the same time.
CONFIG="$HOME/.config/quickshell"

pkill -x waybar
pkill -x swaync

# PIDs of every running copy of this shell (not the lock screen or wallpaper picker,
# which are separate Quickshell configs)
shell_pids() {
    for pid in $(pgrep -x qs; pgrep -x quickshell); do
        tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -qE -- "-p $CONFIG/?( |$)" && echo "$pid"
    done
}

pids="$(shell_pids)"
if [[ -n "$pids" ]]; then
    kill $pids 2>/dev/null
    # Wait up to 3 seconds for them to exit, then force it
    for _ in $(seq 30); do
        [[ -z "$(shell_pids)" ]] && break
        sleep 0.1
    done
    pids="$(shell_pids)"
    [[ -n "$pids" ]] && kill -9 $pids 2>/dev/null
fi

qs -p "$CONFIG" -d

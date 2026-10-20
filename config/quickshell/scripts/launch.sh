#!/usr/bin/env bash
# Start (or restart) the Quickshell desktop. Stops Waybar and swaync, which it replaces.
pkill -x waybar
pkill -x swaync
qs kill -p "$HOME/.config/quickshell" >/dev/null 2>&1
qs -p "$HOME/.config/quickshell" -d

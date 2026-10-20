#!/usr/bin/env bash
# Lock the screen with qylock (theme in ~/.config/qylock/theme).
# hypridle runs this as its lock_cmd, so SUPER+SHIFT+L, the power menu, idle and sleep all end up here.
LOCK="$HOME/.local/share/quickshell-lockscreen/lock.sh"
LOG="${XDG_RUNTIME_DIR:-/tmp}/qylock.log"

# Already locked? Check quickshell processes only (a plain `pgrep -f lock_shell.qml`
# would also match the shell running this check, and then never lock).
for pid in $(pgrep -x quickshell); do
    grep -q "lock_shell.qml" "/proc/$pid/cmdline" 2>/dev/null && exit 0
done

echo "== $(date '+%F %T') locking" >> "$LOG"
exec "$LOCK" >> "$LOG" 2>&1

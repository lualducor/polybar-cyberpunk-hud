#!/bin/bash
set -u

polybar-msg cmd quit >/dev/null 2>&1 || true
pkill -u "$UID" -x polybar >/dev/null 2>&1 || true
for _ in {1..20}; do
    pgrep -u "$UID" -x polybar >/dev/null || break
    sleep 0.1
done

# Ensure clipboard backend exists for the COPYBIN module.
if ! pgrep -u "$UID" -x copyq >/dev/null; then
    copyq &
    sleep 0.3
fi

mapfile -t MONITORS < <(xrandr --listmonitors 2>/dev/null | awk 'NR > 1 {print $NF}')
DETECTED_PRIMARY="$(xrandr --query 2>/dev/null | awk '/ connected primary / {print $1; exit}')"
PRIMARY_MONITOR="${PRIMARY_MONITOR:-${DETECTED_PRIMARY:-${MONITORS[0]:-}}}"

# The secondary HUD belongs on the leftmost non-primary output. This keeps a
# portrait HDMI display mapped correctly even if xrandr changes output order.
DETECTED_SECONDARY="$(xrandr --query 2>/dev/null | awk -v primary="$PRIMARY_MONITOR" '
    / connected / && $1 != primary {
        if (match($0, /\+[0-9]+\+[0-9]+/)) {
            split(substr($0, RSTART + 1, RLENGTH - 1), pos, "+")
            print pos[1], $1
        }
    }
' | sort -n | awk 'NR == 1 {print $2}')"
SECONDARY_MONITOR="${SECONDARY_MONITOR:-${DETECTED_SECONDARY:-$PRIMARY_MONITOR}}"

if [[ -z "$PRIMARY_MONITOR" ]]; then
    notify-send "Cyberpunk HUD" "No XWayland monitor is available" 2>/dev/null || true
    exit 1
fi

export PRIMARY_MONITOR SECONDARY_MONITOR
polybar right &
polybar right-bottom &
if [[ "$SECONDARY_MONITOR" != "$PRIMARY_MONITOR" ]]; then
    polybar left &
fi

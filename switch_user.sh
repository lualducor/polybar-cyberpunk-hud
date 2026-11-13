#!/bin/bash
set -u

TARGET_USER="${I3_TARGET_USER:-lu47}"

target_session="$(loginctl list-sessions --no-legend 2>/dev/null | \
    awk -v user="$TARGET_USER" '$3 == user {print $1; exit}')"

if [[ -z "$target_session" ]]; then
    notify-send "Switch user" "No running session found for $TARGET_USER" 2>/dev/null || true
    exit 1
fi

session_type="$(loginctl show-session "$target_session" -p Type --value 2>/dev/null)"
if [[ "$session_type" != "x11" ]] || ! pgrep -u "$TARGET_USER" -x i3 >/dev/null; then
    notify-send "Switch user" "$TARGET_USER does not currently have a running i3/X11 session" 2>/dev/null || true
    exit 1
fi

exec loginctl activate-session "$target_session"

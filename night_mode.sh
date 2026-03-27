#!/bin/bash
STATE_FILE="/tmp/redshift_manual_state"

case "$1" in
    status)
        if [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "on" ]; then
            echo "%{F#ff8c00}NM ON%{F-}"
        else
            echo "%{F#00f3ff}NM%{F-}"
        fi
        ;;
    toggle)
        if [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "on" ]; then
            redshift -x 2>/dev/null
            echo "off" > "$STATE_FILE"
        else
            redshift -O 3500 2>/dev/null &
            echo "on" > "$STATE_FILE"
        fi
        ;;
esac

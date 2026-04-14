#!/bin/bash
UPTIME_SECS=$(awk '{print int($1)}' /proc/uptime)
HOURS=$((UPTIME_SECS / 3600))
MINUTES=$(( (UPTIME_SECS % 3600) / 60 ))

if [ "$HOURS" -lt 24 ]; then
    COLOR="#39ff14"
elif [ "$HOURS" -lt 72 ]; then
    COLOR="#00f3ff"
elif [ "$HOURS" -lt 168 ]; then
    COLOR="#dfff00"
else
    COLOR="#f7768e"
fi

echo "%{F${COLOR}}UP ${HOURS}h ${MINUTES}m%{F-}"

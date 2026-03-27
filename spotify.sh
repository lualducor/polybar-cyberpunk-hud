#!/bin/bash
STATUS=$(playerctl -p spotify status 2>/dev/null)

if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
    echo "OFFLINE"
    exit 0
fi

TITLE=$(playerctl -p spotify metadata title 2>/dev/null)
ARTIST=$(playerctl -p spotify metadata artist 2>/dev/null)

if [ -z "$TITLE" ]; then
    echo "OFFLINE"
    exit 0
fi

DISPLAY="$ARTIST - $TITLE"

if [ "${#DISPLAY}" -gt 20 ]; then
    echo "${DISPLAY:0:20}..."
else
    echo "$DISPLAY"
fi

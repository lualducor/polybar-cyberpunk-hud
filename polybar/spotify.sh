#!/bin/bash
STATUS=$(playerctl -p spotify status 2>/dev/null)

if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
    echo "OFFLINE"
    exit 0
fi

TITLE=$(playerctl -p spotify metadata title 2>/dev/null)

if [ -z "$TITLE" ]; then
    echo "OFFLINE"
    exit 0
fi

if [ "${#TITLE}" -gt 20 ]; then
    echo "${TITLE:0:20}..."
else
    echo "$TITLE"
fi

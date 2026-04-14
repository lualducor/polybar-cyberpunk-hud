#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v playerctl >/dev/null 2>&1; then
    echo "NO PLAYERCTL"
    exit 0
fi

PLAYER="$("$SCRIPT_DIR/spotify_ctrl.sh" --print-player 2>/dev/null)"

if [ -z "$PLAYER" ]; then
    echo "OFFLINE"
    exit 0
fi

STATUS=$(playerctl --player="$PLAYER" status 2>/dev/null)

if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
    echo "OFFLINE"
    exit 0
fi

TITLE=$(playerctl --player="$PLAYER" metadata title 2>/dev/null)
ARTIST=$(playerctl --player="$PLAYER" metadata artist 2>/dev/null)

if [ -z "$TITLE" ]; then
    echo "OFFLINE"
    exit 0
fi

DISPLAY="$ARTIST - $TITLE"
echo "$DISPLAY"

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYER="$("$SCRIPT_DIR/spotify_ctrl.sh" --print-player 2>/dev/null)"

if [ -z "$PLAYER" ]; then
    dunstify -u low -t 3000 "Spotify" "Player unavailable"
    exit 0
fi

TITLE=$(playerctl --player="$PLAYER" metadata title 2>/dev/null)
ARTIST=$(playerctl --player="$PLAYER" metadata artist 2>/dev/null)

if [ -z "$TITLE" ]; then
    dunstify -u low -t 3000 "Spotify" "Nothing playing"
else
    dunstify -u low -t 3000 "NOW PLAYING" "${ARTIST}\n${TITLE}"
fi

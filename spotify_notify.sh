#!/bin/bash
TITLE=$(playerctl -p spotify metadata title 2>/dev/null)
ARTIST=$(playerctl -p spotify metadata artist 2>/dev/null)

if [ -z "$TITLE" ]; then
    dunstify -u low -t 3000 "Spotify" "Nothing playing"
else
    dunstify -u low -t 3000 "NOW PLAYING" "${ARTIST}\n${TITLE}"
fi

#!/bin/bash
MIC_SOURCE=$(pactl list sources short 2>/dev/null | grep -i "maono\|DGM20" | head -1 | awk '{print $2}')
[ -z "$MIC_SOURCE" ] && MIC_SOURCE="@DEFAULT_SOURCE@"

case "$1" in
    status)
        MUTED=$(pactl get-source-mute "$MIC_SOURCE" 2>/dev/null | grep -o "yes\|no")
        if [ "$MUTED" = "yes" ]; then
            echo "%{F#f7768e}MIC X%{F-}"
        else
            echo "%{F#00f3ff}MIC%{F-}"
        fi
        ;;
    toggle)
        pactl set-source-mute "$MIC_SOURCE" toggle 2>/dev/null
        ;;
esac

#!/bin/bash
STATE_FILE="/tmp/dnd_state"
VOL_FILE="/tmp/dnd_vol_save"

[ ! -f "$STATE_FILE" ] && echo "green" > "$STATE_FILE"

case "$1" in
    status)
        STATE=$(cat "$STATE_FILE")
        case "$STATE" in
            green)  echo "%{F#39ff14}[ON]%{F-}" ;;
            yellow) echo "%{F#dfff00}[SIL]%{F-}" ;;
            red)    echo "%{F#f7768e}[OFF]%{F-}" ;;
        esac
        ;;
    toggle)
        STATE=$(cat "$STATE_FILE")
        case "$STATE" in
            green)
                VOL=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+(?=%)' | head -1)
                echo "${VOL:-50}" > "$VOL_FILE"
                pactl set-sink-mute @DEFAULT_SINK@ 1
                dunstctl set-paused true 2>/dev/null
                echo "yellow" > "$STATE_FILE"
                ;;
            yellow)
                dunstctl set-paused false 2>/dev/null
                pkill dunst 2>/dev/null
                echo "red" > "$STATE_FILE"
                ;;
            red)
                VOL=$(cat "$VOL_FILE" 2>/dev/null || echo "50")
                pactl set-sink-mute @DEFAULT_SINK@ 0
                pactl set-sink-volume @DEFAULT_SINK@ "${VOL}%"
                dunst &
                echo "green" > "$STATE_FILE"
                ;;
        esac
        ;;
esac

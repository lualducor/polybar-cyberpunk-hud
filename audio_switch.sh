#!/bin/bash
SPEAKERS="YOUR_SPEAKERS_SINK"
HEADSET="YOUR_HEADSET_SINK"

case "$1" in
    status)
        CURRENT=$(pactl get-default-sink 2>/dev/null)
        if [ "$CURRENT" = "$HEADSET" ]; then
            echo "%{F#00f3ff}HPH%{F-}"
        else
            echo "%{F#39ff14}SPK%{F-}"
        fi
        ;;
    toggle)
        CURRENT=$(pactl get-default-sink 2>/dev/null)
        if [ "$CURRENT" = "$HEADSET" ]; then
            pactl set-default-sink "$SPEAKERS" 2>/dev/null
        else
            pactl set-default-sink "$HEADSET" 2>/dev/null
        fi
        ;;
esac

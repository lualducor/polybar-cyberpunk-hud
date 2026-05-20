#!/bin/bash
killall -q tray.py
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
sleep 0.5

# Ensure clipboard backend exists for the COPYBIN module.
if ! pgrep -u "$UID" -x copyq >/dev/null; then
    copyq &
    sleep 0.3
fi

polybar left &
polybar right &
polybar right-bottom &

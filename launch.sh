#!/bin/bash
killall -q tray.py
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
sleep 0.5

polybar left &
polybar right &
polybar right-bottom &

#!/bin/bash
CONFIRMED_FILE="/tmp/nuke_session_confirmed"

WID=$(xdotool getactivewindow 2>/dev/null)
if [ -z "$WID" ]; then
    exit 0
fi

WINDOW_NAME=$(xprop -id "$WID" _NET_WM_NAME 2>/dev/null | grep -oP '(?<= = ").*(?=")' | head -1 | cut -c1-25)
[ -z "$WINDOW_NAME" ] && WINDOW_NAME="this process"

do_kill() {
    PID=$(xprop -id "$WID" _NET_WM_PID 2>/dev/null | grep -oP '\d+')
    if [ -n "$PID" ]; then
        kill -9 "$PID" 2>/dev/null
    else
        xdotool windowkill "$WID" 2>/dev/null
    fi
}

if [ ! -f "$CONFIRMED_FILE" ]; then
    CHOICE=$(printf "EXECUTE\nABORT" | rofi -dmenu -i \
        -p "TERMINATE: ${WINDOW_NAME}?" \
        -theme-str 'window {width: 450px;} listview {lines: 2;}')
    if [ "$CHOICE" = "EXECUTE" ]; then
        touch "$CONFIRMED_FILE"
        do_kill
    fi
else
    do_kill
fi

#!/bin/bash

get_active_window_id() {
    xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk -F' ' '{print $5}'
}

get_window_name() {
    local wid="$1"
    xprop -id "$wid" _NET_WM_NAME 2>/dev/null | sed -n 's/.*= "\(.*\)"/\1/p' | head -n1
}

get_window_pid() {
    local wid="$1"
    xprop -id "$wid" _NET_WM_PID 2>/dev/null | awk '{print $3}'
}

close_window() {
    local wid="$1"

    wmctrl -ic "$wid" >/dev/null 2>&1 && exit 0
    command -v xdotool >/dev/null 2>&1 && xdotool windowkill "$wid" >/dev/null 2>&1 && exit 0
    return 1
}

confirm_kill() {
    local label="$1"

    if command -v rofi >/dev/null 2>&1; then
        local theme
        theme='
            * {
                background: #0d1117;
                background-alt: #1b2129;
                foreground: #a9fef7;
                primary: #00f3ff;
                secondary: #39ff14;
                alert: #f7768e;
                disabled: #444444;
            }
            window {
                width: 520px;
                border: 2px;
                border-color: @alert;
                background-color: @background;
            }
            mainbox {
                children: [ inputbar, message, listview ];
                spacing: 14px;
                padding: 18px;
                background-color: @background;
            }
            inputbar {
                padding: 12px;
                border: 1px;
                border-color: @primary;
                background-color: @background-alt;
                text-color: @alert;
            }
            prompt {
                text-color: @alert;
            }
            textbox-prompt-colon {
                text-color: @primary;
            }
            message {
                padding: 10px 12px;
                border: 1px;
                border-color: @background-alt;
                background-color: @background-alt;
            }
            textbox {
                text-color: @foreground;
            }
            listview {
                lines: 2;
                columns: 1;
                spacing: 10px;
                scrollbar: false;
            }
            element {
                padding: 12px;
                border: 1px;
                border-color: @background-alt;
                background-color: @background-alt;
                text-color: @foreground;
            }
            element selected {
                border-color: @alert;
                background-color: @alert;
                text-color: #0b0f14;
            }
            element-text selected {
                text-color: #0b0f14;
            }
        '
        choice=$(printf "EXECUTE\nABORT" | rofi -dmenu -i \
            -p "// NUKE //" \
            -mesg "Target: ${label}" \
            -theme-str "$theme")
        [ "$choice" = "EXECUTE" ]
        return
    fi

    notify-send "NUKE unavailable" "rofi is required for confirmation"
    return 1
}

wid="$(get_active_window_id)"
[ -z "$wid" ] || [ "$wid" = "0x0" ] && exit 0

window_name="$(get_window_name "$wid")"
[ -z "$window_name" ] && window_name="this window"
window_name="${window_name:0:40}"

confirm_kill "$window_name" || exit 0

pid="$(get_window_pid "$wid")"

if [ -n "$pid" ]; then
    kill -TERM "$pid" >/dev/null 2>&1
    sleep 0.4
    kill -0 "$pid" >/dev/null 2>&1 && kill -KILL "$pid" >/dev/null 2>&1
    exit 0
fi

close_window "$wid"

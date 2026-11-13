#!/bin/bash

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

window_name="$(python3 ~/.config/polybar/gnome_hud.py title 2>/dev/null)"
[ -z "$window_name" ] && window_name="this window"
window_name="${window_name:0:40}"

confirm_kill "$window_name" || exit 0
python3 ~/.config/polybar/gnome_hud.py action close

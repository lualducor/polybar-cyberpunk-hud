#!/bin/bash
BT_POWERED=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')

if [ "$BT_POWERED" = "yes" ]; then
    BT_OPTION="UPLINK ONLINE"
else
    BT_OPTION="UPLINK OFFLINE"
fi

CHOSEN=$(printf "NUKE SYSTEM\nREBOOT SEQUENCE\nDISCONNECT\n${BT_OPTION}" | \
    rofi -dmenu -i \
    -p "// SYSTEM CONTROL //" \
    -theme-str 'window {width: 400px;} listview {lines: 4;}')

case "$CHOSEN" in
    "NUKE SYSTEM")     systemctl poweroff ;;
    "REBOOT SEQUENCE") systemctl reboot ;;
    "DISCONNECT")      cinnamon-session-quit --logout --no-prompt ;;
    "UPLINK ONLINE")   bluetoothctl power off ;;
    "UPLINK OFFLINE")  bluetoothctl power on ;;
esac

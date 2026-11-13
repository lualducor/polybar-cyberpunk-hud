#!/bin/bash
BT_POWERED=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')

if [ "$BT_POWERED" = "yes" ]; then
    BT_OPTION="UPLINK ONLINE"
else
    BT_OPTION="UPLINK OFFLINE"
fi

CHOSEN=$(printf "SETTINGS\nNUKE SYSTEM\nREBOOT SEQUENCE\nSWITCH USER → I3\n${BT_OPTION}" | \
    rofi -dmenu -i \
    -p "// SYSTEM CONTROL //" \
    -theme-str 'window {width: 400px; location: north east; anchor: north east; x-offset: -8px; y-offset: 48px;} listview {lines: 5;}')

case "$CHOSEN" in
    "SETTINGS")        gnome-control-center & ;;
    "NUKE SYSTEM")     systemctl poweroff ;;
    "REBOOT SEQUENCE") systemctl reboot ;;
    "SWITCH USER → I3") ~/.config/polybar/switch_user.sh ;;
    "UPLINK ONLINE")   bluetoothctl power off ;;
    "UPLINK OFFLINE")  bluetoothctl power on ;;
esac

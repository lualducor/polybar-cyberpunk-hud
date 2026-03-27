#!/bin/bash
MOONRAKER="http://YOUR_KLIPPER_IP:7125"

DATA=$(curl -s --max-time 3 "${MOONRAKER}/printer/objects/query?print_stats&display_status" 2>/dev/null)

if [ -z "$DATA" ]; then
    echo "%{F#444444} PRINTER OFF %{F-}"
    exit 0
fi

STATE=$(echo "$DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['status']['print_stats']['state'])" 2>/dev/null)
MSG=$(echo "$DATA" | python3 -c "
import sys,json,re
d=json.load(sys.stdin)
m=d['result']['status']['display_status']['message']
m=re.sub(r'(\d+)% done', r'\1%', m)
m=re.sub(r' left', '', m)
print(m)
" 2>/dev/null)

case "$STATE" in
    printing)
        COLOR="#39ff14"
        LABEL=" ${MSG}"
        ;;
    paused)
        COLOR="#dfff00"
        LABEL=" PAUSED"
        ;;
    error)
        COLOR="#f7768e"
        LABEL=" ERROR"
        ;;
    *)
        COLOR="#444444"
        LABEL=" IDLE"
        ;;
esac

echo "%{F${COLOR}}${LABEL}%{F-}"

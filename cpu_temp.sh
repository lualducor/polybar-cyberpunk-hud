#!/bin/bash
TEMP=$(sensors coretemp-isa-0000 2>/dev/null | grep "Core 0" | awk '{print $3}' | tr -d '+°C')

if [ -z "$TEMP" ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    [ -n "$TEMP" ] && TEMP=$((TEMP / 1000))
fi

if [ -z "$TEMP" ]; then
    echo "TEMP N/A"
    exit 0
fi

TEMP_INT=${TEMP%.*}

if [ "$TEMP_INT" -lt 50 ]; then
    COLOR="#39ff14"
elif [ "$TEMP_INT" -lt 70 ]; then
    COLOR="#dfff00"
else
    COLOR="#f7768e"
fi

echo "%{F${COLOR}}TEMP ${TEMP}C%{F-}"

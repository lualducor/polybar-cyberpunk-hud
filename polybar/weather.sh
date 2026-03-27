#!/bin/bash
RESULT=$(curl -s --max-time 5 "wttr.in/Bogota?format=%t+%C" 2>/dev/null)

if [ -z "$RESULT" ]; then
    echo "WTHR N/A"
    exit 0
fi

TEMP=$(echo "$RESULT" | grep -oP '[+-]?\d+°C' | head -1)
CONDITION=$(echo "$RESULT" | sed 's/[+-]*[0-9]*°C //' | xargs | tr '[:upper:]' '[:lower:]')

if [ -z "$TEMP" ]; then
    echo "WTHR N/A"
    exit 0
fi

# Shorten condition to one word
case "$CONDITION" in
    *thunder*|*storm*)         SHORT="Storm";   COLOR="#f7768e" ;;
    *heavy*rain*|*freezing*)   SHORT="HvyRain"; COLOR="#f7768e" ;;
    *rain*)                    SHORT="Rain";    COLOR="#f7768e" ;;
    *snow*|*blizzard*|*hail*|*sleet*|*ice*) SHORT="Snow"; COLOR="#f7768e" ;;
    *drizzle*|*shower*|*vicinity*) SHORT="Showers"; COLOR="#dfff00" ;;
    *mist*|*fog*|*haze*)       SHORT="Foggy";   COLOR="#dfff00" ;;
    *wind*)                    SHORT="Windy";   COLOR="#dfff00" ;;
    *overcast*)                SHORT="Overcast"; COLOR="#39ff14" ;;
    *cloud*|*partly*)          SHORT="Cloudy";  COLOR="#39ff14" ;;
    *clear*|*sunny*)           SHORT="Clear";   COLOR="#39ff14" ;;
    *)                         SHORT="OK";      COLOR="#39ff14" ;;
esac

echo "%{F${COLOR}}${TEMP} ${SHORT}%{F-}"

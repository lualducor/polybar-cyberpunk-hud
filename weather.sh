#!/bin/bash
# Open-Meteo API — no key needed, free forever
URL="https://api.open-meteo.com/v1/forecast?latitude=4.71&longitude=-74.07&current=temperature_2m,weathercode&timezone=America/Bogota"

DATA=$(curl -s --max-time 5 "$URL" 2>/dev/null)

if [ -z "$DATA" ]; then
    echo "WTHR N/A"
    exit 0
fi

TEMP=$(echo "$DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(int(d['current']['temperature_2m']))" 2>/dev/null)
CODE=$(echo "$DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current']['weathercode'])" 2>/dev/null)

if [ -z "$TEMP" ] || [ -z "$CODE" ]; then
    echo "WTHR N/A"
    exit 0
fi

# WMO weather code to short description and color
# Green: clear/cloudy | Yellow: drizzle/fog/wind | Red: rain/storm/snow
case "$CODE" in
    0)                          SHORT="Clear";    COLOR="#39ff14" ;;
    1|2)                        SHORT="Partly";   COLOR="#39ff14" ;;
    3)                          SHORT="Overcast"; COLOR="#39ff14" ;;
    45|48)                      SHORT="Foggy";    COLOR="#dfff00" ;;
    51|53)                      SHORT="Drizzle";  COLOR="#dfff00" ;;
    55)                         SHORT="HvyDrz";   COLOR="#f7768e" ;;
    56|57)                      SHORT="FrzDrz";   COLOR="#f7768e" ;;
    61|63)                      SHORT="Rain";     COLOR="#f7768e" ;;
    65)                         SHORT="HvyRain";  COLOR="#f7768e" ;;
    66|67)                      SHORT="FrzRain";  COLOR="#f7768e" ;;
    71|73)                      SHORT="Snow";     COLOR="#f7768e" ;;
    75)                         SHORT="HvySnow";  COLOR="#f7768e" ;;
    77)                         SHORT="Hail";     COLOR="#f7768e" ;;
    80|81)                      SHORT="Showers";  COLOR="#dfff00" ;;
    82)                         SHORT="HvyShwr";  COLOR="#f7768e" ;;
    85|86)                      SHORT="SnwShwr";  COLOR="#f7768e" ;;
    95)                         SHORT="Storm";    COLOR="#f7768e" ;;
    96|99)                      SHORT="Hailstrm"; COLOR="#f7768e" ;;
    *)                          SHORT="OK";       COLOR="#39ff14" ;;
esac

echo "%{F${COLOR}}${TEMP}°C ${SHORT}%{F-}"

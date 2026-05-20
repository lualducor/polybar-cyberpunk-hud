#!/bin/bash
MOONRAKER="${MOONRAKER_URL:-http://192.168.40.35:7125}"
WINDOW=${KLIPPER_WINDOW:-0}

DATA=$(curl -s --max-time 3 "${MOONRAKER}/printer/objects/query?print_stats&display_status&virtual_sdcard" 2>/dev/null)

if [ -z "$DATA" ]; then
    echo "%{F#444444} P OFF %{F-}"
    exit 0
fi

STATUS=$(echo "$DATA" | python3 -c "
import json
import re
import sys

data = json.load(sys.stdin)['result']['status']
print_stats = data.get('print_stats', {})
display_status = data.get('display_status', {})
virtual_sdcard = data.get('virtual_sdcard', {})

def format_duration(seconds):
    seconds = max(0, int(round(seconds)))
    hours, rem = divmod(seconds, 3600)
    minutes, secs = divmod(rem, 60)
    parts = []
    if hours:
        parts.append(f'{hours}h')
    if minutes or hours:
        parts.append(f'{minutes}m')
    if not hours and not minutes:
        parts.append(f'{secs}s')
    return ''.join(parts) if parts else '0s'

state = str(print_stats.get('state', 'unknown')).strip().lower()
message = str(display_status.get('message') or '').strip()
message = re.sub(r'\s+', ' ', message)
progress = display_status.get('progress')
if progress is None:
    progress = virtual_sdcard.get('progress')
print_duration = print_stats.get('print_duration')

if isinstance(progress, (int, float)):
    progress_text = f'{round(progress * 100):.0f}%'
else:
    progress_match = re.search(r'(\d+(?:\.\d+)?)\s*%\s*(?:done)?', message, flags=re.I)
    progress_text = f\"{round(float(progress_match.group(1))):.0f}%\" if progress_match else '--'

eta_text = '--'
if isinstance(progress, (int, float)) and isinstance(print_duration, (int, float)) and 0 < progress < 1:
    remaining = (print_duration / progress) - print_duration
    eta_text = format_duration(remaining)
else:
    eta_match = re.search(
        r'((?:\d+\s*[hms]\s*)+)\s*(?:left|remaining)\b',
        message,
        flags=re.I,
    )
    if not eta_match:
        eta_match = re.search(r'\bETA[: ]+((?:\d+\s*[hms]\s*)+)', message, flags=re.I)
    if eta_match:
        eta_text = re.sub(r'\s+', '', eta_match.group(1))

status_text = {
    'printing': 'PRINTING',
    'paused': 'PAUSED',
    'error': 'ERROR',
    'complete': 'COMPLETE',
    'standby': 'IDLE',
}.get(state, state.upper() or 'UNKNOWN')

print(state)
print(f'{status_text}|{progress_text}|{eta_text}')
" 2>/dev/null)

STATE=$(printf '%s\n' "$STATUS" | sed -n '1p')
MSG=$(printf '%s\n' "$STATUS" | sed -n '2p')

case "$STATE" in
    printing)
        COLOR="#39ff14"
        if [ "$WINDOW" -gt 0 ] && [ ${#MSG} -gt "$WINDOW" ]; then
            PADDED="${MSG}   "
            OFFSET=$(( $(date +%s) % ${#PADDED} ))
            LABEL="${PADDED:$OFFSET:$WINDOW}"
            if [ ${#LABEL} -lt "$WINDOW" ]; then
                LABEL="${LABEL}${PADDED:0:$((WINDOW - ${#LABEL}))}"
            fi
            LABEL="${LABEL}"
        else
            LABEL="${MSG}"
        fi
        ;;
    paused)
        COLOR="#dfff00"
        LABEL="${MSG}"
        ;;
    error)
        COLOR="#f7768e"
        LABEL="${MSG}"
        ;;
    *)
        COLOR="#444444"
        LABEL="${MSG}"
        ;;
esac

echo "%{F${COLOR}}${LABEL}%{F-}"

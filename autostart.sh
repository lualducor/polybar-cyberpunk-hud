#!/bin/bash
# ============================================================
# POLYBAR MASTER AUTOSTART
# Correct launch order: dunst → copyq → redshift → polybar
# ============================================================

# Kill any stale instances
killall -q polybar
killall -q tray.py
killall -q dunst
killall -q copyq

sleep 0.5

# 1. Dunst must start first — DND module depends on it
dunst &
sleep 0.5

# 2. copyq clipboard daemon — silent background
copyq &
sleep 0.3

# 3. Redshift — Bogota coords, schedule-based, starts inactive
redshift -l 4.7110:-74.0721 &
sleep 0.3

# 4. Disable Cinnamon session restore
gsettings set org.cinnamon.SessionManager auto-save-session false 2>/dev/null

# 5. Initialize DND to green on every boot
echo "green" > /tmp/dnd_state

# 6. Start bars
~/.config/polybar/launch.sh

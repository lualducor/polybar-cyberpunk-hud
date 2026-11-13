#!/bin/bash
# ============================================================
# POLYBAR MASTER AUTOSTART
# GNOME Wayland launch order: helpers → Polybar/XWayland
# ============================================================

# Kill any stale instances
# Start optional helpers without replacing GNOME/session services.
pgrep -u "$UID" -x dunst >/dev/null || dunst &
sleep 0.5

# 2. copyq clipboard daemon — silent background
pgrep -u "$UID" -x copyq >/dev/null || copyq &
sleep 0.3

# 3. Redshift — Bogota coords, schedule-based, starts inactive
pgrep -u "$UID" -x redshift >/dev/null || redshift -l 4.7110:-74.0721 &
sleep 0.3

# Initialize DND state.
echo "green" > /tmp/dnd_state

# Start bars after GNOME Shell and XWayland settle.
~/.config/polybar/launch.sh

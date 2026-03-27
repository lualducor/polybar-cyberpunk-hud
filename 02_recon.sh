#!/bin/bash

# ============================================================
# POLYBAR RECON SCRIPT
# Collects all system info needed to build the bar
# Run this AFTER cleanup, BEFORE build
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MISSING=()
OUTPUT_FILE="/tmp/polybar_recon.txt"

echo -e "${CYAN}"
echo " ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗"
echo " ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║"
echo " ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║"
echo " ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║"
echo " ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║"
echo " ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${CYAN}// SYSTEM RECON — COLLECTING BUILD DATA //${NC}"
echo ""

# Start output file
echo "POLYBAR RECON OUTPUT" > $OUTPUT_FILE
echo "Generated: $(date)" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE

# ------------------------------------------------------------
# STEP 1: Network interface
# ------------------------------------------------------------
echo -e "${YELLOW}[01]${NC} Network interfaces..."
INTERFACES=$(ip link | grep -E "^[0-9]" | awk '{print $2}' | tr -d ':')
echo "$INTERFACES" | while read iface; do
    echo -e "${CYAN}     $iface${NC}"
done
echo ""
echo "NETWORK INTERFACES:" >> $OUTPUT_FILE
echo "$INTERFACES" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Try to detect the active wired interface
WIRED=$(ip link | grep -E "^[0-9]" | awk '{print $2}' | tr -d ':' | grep -E "^e" | head -1)
if [ -n "$WIRED" ]; then
    echo -e "${GREEN}     ✓ Detected wired interface: ${WIRED}${NC}"
    echo "DETECTED WIRED INTERFACE: $WIRED" >> $OUTPUT_FILE
else
    echo -e "${RED}     ✗ No wired interface detected — check manually${NC}"
    echo "DETECTED WIRED INTERFACE: NOT FOUND" >> $OUTPUT_FILE
fi
echo "" >> $OUTPUT_FILE

# ------------------------------------------------------------
# STEP 2: Dunst
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[02]${NC} Checking notification daemon..."
DUNST_PROC=$(ps aux | grep dunst | grep -v grep)
if [ -n "$DUNST_PROC" ]; then
    echo -e "${GREEN}     ✓ dunst is running${NC}"
    echo "DUNST: RUNNING" >> $OUTPUT_FILE
else
    echo -e "${RED}     ✗ dunst NOT running — DND module will not work${NC}"
    echo "DUNST: NOT RUNNING" >> $OUTPUT_FILE
    MISSING+=("dunst")
fi
echo "" >> $OUTPUT_FILE

# ------------------------------------------------------------
# STEP 3: Audio sinks
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[03]${NC} Audio sinks..."
SINKS=$(pactl list short sinks)
echo "$SINKS" | while read line; do
    echo -e "${CYAN}     $line${NC}"
done
echo "AUDIO SINKS:" >> $OUTPUT_FILE
echo "$SINKS" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Try to detect headset and speakers
HEADSET=$(pactl list short sinks | grep -i "corsair\|headset\|usb" | head -1 | awk '{print $2}')
SPEAKERS=$(pactl list short sinks | grep -iv "corsair\|headset\|usb" | head -1 | awk '{print $2}')
if [ -n "$HEADSET" ]; then
    echo -e "${GREEN}     ✓ Headset detected: ${HEADSET}${NC}"
    echo "HEADSET SINK: $HEADSET" >> $OUTPUT_FILE
else
    echo -e "${RED}     ✗ Headset not detected — will need manual config${NC}"
    echo "HEADSET SINK: NOT DETECTED" >> $OUTPUT_FILE
fi
if [ -n "$SPEAKERS" ]; then
    echo -e "${GREEN}     ✓ Speakers detected: ${SPEAKERS}${NC}"
    echo "SPEAKERS SINK: $SPEAKERS" >> $OUTPUT_FILE
else
    echo -e "${RED}     ✗ Speakers not detected — will need manual config${NC}"
    echo "SPEAKERS SINK: NOT DETECTED" >> $OUTPUT_FILE
fi
echo "" >> $OUTPUT_FILE

# ------------------------------------------------------------
# STEP 4: CPU temperature
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[04]${NC} CPU temperature sensors..."
if command -v sensors &> /dev/null; then
    TEMPS=$(sensors | grep -i "core\|temp")
    echo "$TEMPS" | while read line; do
        echo -e "${CYAN}     $line${NC}"
    done
    echo "CPU TEMPS:" >> $OUTPUT_FILE
    echo "$TEMPS" >> $OUTPUT_FILE
else
    echo -e "${RED}     ✗ lm-sensors not installed${NC}"
    echo "CPU TEMPS: lm-sensors NOT INSTALLED" >> $OUTPUT_FILE
    MISSING+=("lm-sensors")
fi
echo "" >> $OUTPUT_FILE

# ------------------------------------------------------------
# STEP 5: Required tools
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[05]${NC} Checking required tools..."
echo "REQUIRED TOOLS:" >> $OUTPUT_FILE

check_tool() {
    local tool=$1
    local pkg=$2
    if command -v $tool &> /dev/null; then
        echo -e "${GREEN}     ✓ $tool${NC}"
        echo "  $tool: OK" >> $OUTPUT_FILE
    else
        echo -e "${RED}     ✗ $tool — MISSING (install: sudo apt install $pkg)${NC}"
        echo "  $tool: MISSING — sudo apt install $pkg" >> $OUTPUT_FILE
        MISSING+=("$pkg")
    fi
}

check_tool "polybar"        "polybar"
check_tool "rofi"           "rofi"
check_tool "playerctl"      "playerctl"
check_tool "dunstctl"       "dunst"
check_tool "xdotool"        "xdotool"
check_tool "wmctrl"         "wmctrl"
check_tool "bluetoothctl"   "bluez"
check_tool "blueman-manager" "blueman"
check_tool "copyq"          "copyq"
check_tool "redshift"       "redshift"
check_tool "gnome-screenshot" "gnome-screenshot"
check_tool "nemo"           "nemo"
check_tool "btop"           "btop"
check_tool "curl"           "curl"
check_tool "pactl"          "pulseaudio-utils"
check_tool "sensors"        "lm-sensors"

echo "" >> $OUTPUT_FILE

# ------------------------------------------------------------
# STEP 6: Monitor layout
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[06]${NC} Monitor layout..."
MONITORS=$(xrandr --query | grep " connected")
echo "$MONITORS" | while read line; do
    echo -e "${CYAN}     $line${NC}"
done
echo "MONITORS:" >> $OUTPUT_FILE
echo "$MONITORS" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# ------------------------------------------------------------
# STEP 7: Fonts
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[07]${NC} Checking JetBrainsMono Nerd Font..."
if fc-list | grep -qi "JetBrainsMono Nerd"; then
    echo -e "${GREEN}     ✓ JetBrainsMono Nerd Font installed${NC}"
    echo "JETBRAINSMONO NERD FONT: OK" >> $OUTPUT_FILE
else
    echo -e "${RED}     ✗ JetBrainsMono Nerd Font NOT found${NC}"
    echo "JETBRAINSMONO NERD FONT: MISSING" >> $OUTPUT_FILE
    MISSING+=("jetbrainsmono-nerd-font")
fi
echo "" >> $OUTPUT_FILE

# ------------------------------------------------------------
# STEP 8: Weather test
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[08]${NC} Testing weather API (wttr.in Bogota)..."
if command -v curl &> /dev/null; then
    WEATHER=$(curl -s "wttr.in/Bogota?format=%t+%C" 2>/dev/null)
    if [ -n "$WEATHER" ]; then
        echo -e "${GREEN}     ✓ Weather API reachable: ${WEATHER}${NC}"
        echo "WEATHER API: OK — $WEATHER" >> $OUTPUT_FILE
    else
        echo -e "${RED}     ✗ Weather API unreachable — check internet connection${NC}"
        echo "WEATHER API: UNREACHABLE" >> $OUTPUT_FILE
    fi
else
    echo -e "${RED}     ✗ curl not installed — weather will not work${NC}"
fi
echo "" >> $OUTPUT_FILE

# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------
echo ""
echo "======================================" >> $OUTPUT_FILE
echo "MISSING PACKAGES:" >> $OUTPUT_FILE

if [ ${#MISSING[@]} -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ALL SYSTEMS GO — NOTHING MISSING          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo "NONE — all clear" >> $OUTPUT_FILE
else
    echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  MISSING PACKAGES — INSTALL BEFORE BUILD   ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Run this to install everything missing:${NC}"
    INSTALL_LIST=$(echo "${MISSING[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    echo -e "${CYAN}sudo apt install ${INSTALL_LIST}${NC}"
    echo ""
    for pkg in "${MISSING[@]}"; do
        echo "  - $pkg" >> $OUTPUT_FILE
    done
    echo "" >> $OUTPUT_FILE
    echo "INSTALL COMMAND:" >> $OUTPUT_FILE
    echo "sudo apt install ${INSTALL_LIST}" >> $OUTPUT_FILE
fi

echo ""
echo -e "${CYAN}Full recon saved to: ${OUTPUT_FILE}${NC}"
echo ""
echo -e "${CYAN}Paste the contents of that file to Claude:${NC}"
echo -e "${CYAN}cat ${OUTPUT_FILE}${NC}"
echo ""

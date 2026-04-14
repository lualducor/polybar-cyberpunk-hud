#!/bin/bash

# ============================================================
# POLYBAR CLEANUP SCRIPT
# Wipes old configs, kills stale processes, clears all cache
# Run this FIRST before setup
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗ "
echo " ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗"
echo " ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝"
echo " ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝ "
echo " ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║     "
echo "  ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     "
echo -e "${NC}"
echo -e "${CYAN}// POLYBAR ENVIRONMENT CLEANUP //${NC}"
echo ""

# ------------------------------------------------------------
# STEP 1: Kill running processes
# ------------------------------------------------------------
echo -e "${YELLOW}[01]${NC} Killing running Polybar instances..."
killall -q polybar
sleep 1
if pgrep -x polybar > /dev/null; then
    echo -e "${RED}     ✗ Polybar still running — force killing...${NC}"
    pkill -9 polybar
else
    echo -e "${GREEN}     ✓ Polybar terminated${NC}"
fi

echo -e "${YELLOW}[02]${NC} Killing tray.py..."
killall -q tray.py
echo -e "${GREEN}     ✓ Done${NC}"

echo -e "${YELLOW}[03]${NC} Killing stale tray managers..."
killall -q stalonetray 2>/dev/null
killall -q trayer 2>/dev/null
echo -e "${GREEN}     ✓ Done${NC}"

# ------------------------------------------------------------
# STEP 2: Backup existing configs
# ------------------------------------------------------------
echo ""
BACKUP_DIR=~/.config/polybar_backup_$(date +%Y%m%d_%H%M%S)
echo -e "${YELLOW}[04]${NC} Creating backup at ${BACKUP_DIR}..."
mkdir -p "$BACKUP_DIR"

if [ -d ~/.config/polybar ]; then
    cp -r ~/.config/polybar/. "$BACKUP_DIR/polybar/"
    echo -e "${GREEN}     ✓ Polybar config backed up${NC}"
else
    echo -e "${CYAN}     ~ No polybar config dir found, skipping${NC}"
fi

if [ -d ~/.config/rofi ]; then
    cp -r ~/.config/rofi/. "$BACKUP_DIR/rofi/"
    echo -e "${GREEN}     ✓ Rofi config backed up${NC}"
else
    echo -e "${CYAN}     ~ No rofi config dir found, skipping${NC}"
fi

if [ -f ~/launch_polybar.sh ]; then
    cp ~/launch_polybar.sh "$BACKUP_DIR/launch_polybar.sh"
    echo -e "${GREEN}     ✓ ~/launch_polybar.sh backed up${NC}"
fi

if [ -f ~/reload_bar.sh ]; then
    cp ~/reload_bar.sh "$BACKUP_DIR/reload_bar.sh"
    echo -e "${GREEN}     ✓ ~/reload_bar.sh backed up${NC}"
fi

echo -e "${GREEN}     ✓ Full backup saved to: ${BACKUP_DIR}${NC}"

# ------------------------------------------------------------
# STEP 3: Wipe polybar config directory entirely
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[05]${NC} Wiping ~/.config/polybar/ entirely..."
rm -rf ~/.config/polybar/
mkdir -p ~/.config/polybar/
echo -e "${GREEN}     ✓ Fresh empty dir created${NC}"

# ------------------------------------------------------------
# STEP 4: Wipe polybar cache
# ------------------------------------------------------------
echo -e "${YELLOW}[06]${NC} Clearing ~/.cache/polybar/..."
rm -rf ~/.cache/polybar/
echo -e "${GREEN}     ✓ Done${NC}"

# ------------------------------------------------------------
# STEP 5: Clear tmp files
# ------------------------------------------------------------
echo -e "${YELLOW}[07]${NC} Clearing tmp files..."
rm -f /tmp/polybar* 2>/dev/null
rm -f /tmp/polybar-ipc-* 2>/dev/null
rm -f /tmp/dnd_state 2>/dev/null
rm -f /tmp/nuke_confirmed 2>/dev/null
echo -e "${GREEN}     ✓ Done${NC}"

# ------------------------------------------------------------
# STEP 6: Remove old scripts from home directory
# ------------------------------------------------------------
echo -e "${YELLOW}[08]${NC} Removing old scripts from home directory..."
rm -f ~/launch_polybar.sh
rm -f ~/reload_bar.sh
echo -e "${GREEN}     ✓ Done${NC}"

# ------------------------------------------------------------
# STEP 7: Clean rofi scripts (keep theme, remove old sh files)
# ------------------------------------------------------------
echo -e "${YELLOW}[09]${NC} Cleaning old Rofi scripts..."
rm -f ~/.config/rofi/powermenu.sh
rm -f ~/.config/rofi/powermenu_old.sh
echo -e "${GREEN}     ✓ Done${NC}"

# ------------------------------------------------------------
# STEP 8: Fix autostart entry
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}[10]${NC} Checking autostart entry..."
if [ -f ~/.config/autostart/polybar.desktop ]; then
    CURRENT_CMD=$(grep "^Exec=" ~/.config/autostart/polybar.desktop | cut -d= -f2)
    echo -e "${CYAN}     Current: ${CURRENT_CMD}${NC}"
    if echo "$CURRENT_CMD" | grep -qE "mybar|secondary|reload_bar"; then
        echo -e "${RED}     ✗ Stale entry detected — fixing...${NC}"
        sed -i "s|^Exec=.*|Exec=/home/$USER/.config/polybar/launch.sh|" ~/.config/autostart/polybar.desktop
        echo -e "${GREEN}     ✓ Fixed to: /home/$USER/.config/polybar/launch.sh${NC}"
    else
        echo -e "${GREEN}     ✓ Autostart looks clean${NC}"
    fi
else
    echo -e "${CYAN}     ~ No autostart entry found — will be created by setup script${NC}"
fi

# ------------------------------------------------------------
# DONE
# ------------------------------------------------------------
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  CLEANUP COMPLETE — ENVIRONMENT READY  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Backup location: ${BACKUP_DIR}${NC}"
echo -e "${CYAN}Run 02_recon.sh next.${NC}"
echo ""

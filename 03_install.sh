#!/bin/bash
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"
# ============================================================
# POLYBAR INSTALL SCRIPT
# Drops all files, sets permissions, configures services
# Run from the same directory as all the other files
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLYBAR_DIR="$HOME/.config/polybar"
ROFI_DIR="$HOME/.config/rofi"

echo -e "${CYAN}"
echo " ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗"
echo " ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║"
echo " ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║"
echo " ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║"
echo " ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗"
echo " ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
echo -e "${NC}"
echo -e "${CYAN}// POLYBAR INSTALL //${NC}"
echo ""

# Create directories
echo -e "${YELLOW}[01]${NC} Creating directories..."
mkdir -p "$POLYBAR_DIR"
mkdir -p "$ROFI_DIR"
mkdir -p "$HOME/.config/copyq"
echo -e "${GREEN}     ✓ Done${NC}"

# Install polybar config and scripts
echo -e "${YELLOW}[02]${NC} Installing polybar files..."
FILES=(
    "config.ini"
    "launch.sh"
    "autostart.sh"
    "dnd.sh"
    "weather.sh"
    "audio_switch.sh"
    "nuke.sh"
    "night_mode.sh"
    "quick_notes.sh"
    "spotify.sh"
    "mic.sh"
    "cpu_temp.sh"
    "uptime.sh"
    "local_ip.sh"
    "klipper.sh"
    "spotify_notify.sh"
    "ai_budget.py"
    "update_gemini_budget.py"
    "identify_audio_sinks.sh"
)

for f in "${FILES[@]}"; do
    if [ -f "$SCRIPT_DIR/$f" ]; then
        cp "$SCRIPT_DIR/$f" "$POLYBAR_DIR/$f"
        echo -e "${GREEN}     ✓ $f${NC}"
    else
        echo -e "${RED}     ✗ $f NOT FOUND in $SCRIPT_DIR${NC}"
    fi
done

# Install rofi scripts
echo -e "${YELLOW}[03]${NC} Installing rofi scripts..."
if [ -f "$SCRIPT_DIR/rofi/powermenu.sh" ]; then
    cp "$SCRIPT_DIR/rofi/powermenu.sh" "$ROFI_DIR/powermenu.sh"
    echo -e "${GREEN}     ✓ powermenu.sh${NC}"
elif [ -f "$SCRIPT_DIR/powermenu.sh" ]; then
    cp "$SCRIPT_DIR/powermenu.sh" "$ROFI_DIR/powermenu.sh"
    echo -e "${GREEN}     ✓ powermenu.sh${NC}"
else
    echo -e "${RED}     ✗ powermenu.sh NOT FOUND${NC}"
fi

# Set permissions
echo -e "${YELLOW}[04]${NC} Setting permissions..."
chmod +x "$POLYBAR_DIR"/*.sh
chmod +x "$ROFI_DIR/powermenu.sh"
echo -e "${GREEN}     ✓ All scripts executable${NC}"

# Configure copyq dark theme
echo -e "${YELLOW}[05]${NC} Configuring copyq..."
copyq config theme dark 2>/dev/null || true
echo -e "${GREEN}     ✓ Dark theme set${NC}"

# Configure redshift for Bogota
echo -e "${YELLOW}[06]${NC} Configuring redshift for Bogota..."
cat > "$HOME/.config/redshift.conf" << 'REDSHIFT'
[redshift]
temp-day=6500
temp-night=3500
fade=1
lat=4.71
lon=-74.07
REDSHIFT
echo -e "${GREEN}     ✓ Bogota coords set (4.71N, 74.07W)${NC}"

# Disable Cinnamon session restore
echo -e "${YELLOW}[07]${NC} Disabling Cinnamon session restore..."
gsettings set org.cinnamon.SessionManager auto-save-session false 2>/dev/null
echo -e "${GREEN}     ✓ Done${NC}"

# Update autostart entry
echo -e "${YELLOW}[08]${NC} Updating autostart entry..."
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/polybar.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Exec=/home/$USER/.config/polybar/autostart.sh
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[en_US]=polybar
Comment[en_US]=Polybar HUD with all services
X-GNOME-Autostart-Delay=3
DESKTOP
echo -e "${GREEN}     ✓ Autostart updated${NC}"

# Initialize state files
echo -e "${YELLOW}[09]${NC} Initializing state files..."
echo "green" > /tmp/dnd_state
echo -e "${GREEN}     ✓ DND initialized to green${NC}"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  INSTALL COMPLETE — LAUNCHING NOW        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""

# Launch everything
"$POLYBAR_DIR/autostart.sh"

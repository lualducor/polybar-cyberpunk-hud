#!/bin/bash
# setup.sh — install and configure polybar-cyberpunk-hud on a new system
# Run once after cloning: bash setup.sh
set -e

DEST="$HOME/.config/polybar"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== polybar-cyberpunk-hud setup ==="
echo ""

# --- Network interface ---
echo "Available network interfaces:"
ip link show | awk -F': ' '/^[0-9]+:/ && !/lo/ {print "  " $2}'
echo ""
read -rp "Network interface to monitor (e.g. eth0, enp3s0): " NET_IFACE
if [[ -z "$NET_IFACE" ]]; then
    echo "No interface provided, skipping network module patch."
fi

# --- Klipper / Moonraker ---
echo ""
read -rp "Moonraker URL (leave blank to skip, e.g. http://192.168.1.100:7125): " MOONRAKER
if [[ -z "$MOONRAKER" ]]; then
    echo "Skipping Klipper/Moonraker config."
fi

# --- AI workdir ---
echo ""
read -rp "Working directory for AI terminals (default: \$HOME): " AI_WORKDIR
AI_WORKDIR="${AI_WORKDIR:-$HOME}"

# --- Copy files ---
echo ""
echo "Copying files to $DEST ..."
mkdir -p "$DEST"
cp "$REPO_DIR"/*.sh "$DEST/"
cp "$REPO_DIR"/*.py "$DEST/"
cp "$REPO_DIR"/config.ini "$DEST/"
chmod +x "$DEST"/*.sh

# Copy ai_budget.env from example if it doesn't exist yet
if [[ ! -f "$DEST/ai_budget.env" ]]; then
    cp "$REPO_DIR/ai_budget.env.example" "$DEST/ai_budget.env"
    echo "Created $DEST/ai_budget.env — fill in your API keys."
fi

# Copy gemini_budget.json from example if it doesn't exist yet
if [[ ! -f "$DEST/gemini_budget.json" ]]; then
    cp "$REPO_DIR/gemini_budget.json.example" "$DEST/gemini_budget.json"
fi

# --- Patch values ---
echo "Patching config..."

# Network interface
if [[ -n "$NET_IFACE" ]]; then
    escaped_iface=$(printf '%s\n' "$NET_IFACE" | sed 's/[\/&]/\\&/g')
    sed -i -E "s|^interface = .*|interface = $escaped_iface|" "$DEST/config.ini"
fi

# Klipper IP
if [[ -n "$MOONRAKER" ]]; then
    # Strip trailing slash
    MOONRAKER="${MOONRAKER%/}"
    escaped_moonraker=$(printf '%s\n' "$MOONRAKER" | sed 's/[\/&]/\\&/g')
    moonraker_host=$(printf '%s\n' "$MOONRAKER" | sed -E 's#^(https?://[^/:]+).*#\1#')
    escaped_moonraker_host=$(printf '%s\n' "$moonraker_host" | sed 's/[\/&]/\\&/g')

    sed -i -E "s|^MOONRAKER=.*|MOONRAKER=\"\${MOONRAKER_URL:-$escaped_moonraker}\"|" "$DEST/klipper.sh"
    sed -i -E "s|^click-left = xdg-open .*&$|click-left = xdg-open \"\${MOONRAKER_HOST:-$escaped_moonraker_host}\" \\&|" "$DEST/config.ini"
fi

# AI workdir
escaped_ai_workdir=$(printf '%s\n' "$AI_WORKDIR" | sed 's/[\/&]/\\&/g')
sed -i -E "s|^WORKDIR=.*|WORKDIR=\"\${AI_WORKDIR:-$escaped_ai_workdir}\"|" "$DEST/ai_cli_launcher.sh"

echo ""
echo "Done. Next steps:"
echo "  1. Edit $DEST/ai_budget.env and fill in your API keys."
echo "  2. Check $DEST/config.ini — adjust monitor names (DP-2, HDMI-0) to your outputs."
echo "     Run: xrandr --listmonitors"
echo "  3. Launch polybar: bash $DEST/launch.sh"

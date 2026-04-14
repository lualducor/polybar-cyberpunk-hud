POLYBAR CYBERPUNK HUD — BACKUP
================================
Generated: 2026-04-14
System: Linux Mint / Cinnamon

MONITORS:
- Primary   → landscape (main HUD) — set monitor = in [bar/right]
- Secondary → portrait  (display only) — set monitor = in [bar/left]

BARS:
- right        → primary top bar
- right-bottom → primary bottom bar (workspaces only)
- left         → secondary portrait bar

INSTALL ORDER:
1. sudo apt install btop copyq dunst redshift xterm polybar rofi playerctl xdotool wmctrl bluez blueman gnome-screenshot nemo curl lm-sensors pulseaudio-utils
2. Install JetBrainsMono Nerd Font to ~/.local/share/fonts/
3. bash setup.sh   (interactive — patches all system-specific values)
   -- OR manually:
   chmod +x 01_cleanup.sh 02_recon.sh 03_install.sh
   ./01_cleanup.sh
   ./02_recon.sh  (verify all tools found)
   ./03_install.sh

FILE LOCATIONS AFTER INSTALL:
- ~/.config/polybar/config.ini
- ~/.config/polybar/launch.sh
- ~/.config/polybar/autostart.sh
- ~/.config/polybar/*.sh  (all scripts)
- ~/.config/rofi/powermenu.sh
- ~/.config/autostart/polybar.desktop

SYSTEM-SPECIFIC VALUES TO CONFIGURE:
- Network interface: config.ini → interface = YOUR_NET_IFACE
  (find yours: ip link show)
- Klipper/Moonraker: klipper.sh → MOONRAKER_URL env var or fallback default
  (also config.ini → klipper module click-left)
- Audio sinks: audio_switch.sh
  (find yours: pactl list short sinks)
- AI API keys: ~/.config/polybar/ai_budget.env
  (copy from ai_budget.env.example)

NOTE: On a new system run 02_recon.sh first to get correct
interface names, audio sinks and sensor paths before deploying.

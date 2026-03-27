POLYBAR CYBERPUNK HUD — BACKUP
================================
Generated: 2026-03-26
System: Linux Mint / Cinnamon
User: lu47

MONITORS:
- DP-2    → Primary landscape 2560x1440 (main HUD)
- HDMI-0  → Portrait 1080x1920 (display only)

BARS:
- right        → DP-2 top bar
- right-bottom → DP-2 bottom bar (workspaces only)
- left         → HDMI-0 portrait bar

INSTALL ORDER:
1. sudo apt install btop copyq dunst redshift xterm polybar rofi playerctl xdotool wmctrl bluez blueman gnome-screenshot nemo curl lm-sensors pulseaudio-utils
2. Install JetBrainsMono Nerd Font to ~/.local/share/fonts/
3. chmod +x 01_cleanup.sh 02_recon.sh 03_install.sh
4. ./01_cleanup.sh
5. ./02_recon.sh  (verify all tools found)
6. ./03_install.sh

FILE LOCATIONS AFTER INSTALL:
- ~/.config/polybar/config.ini
- ~/.config/polybar/launch.sh
- ~/.config/polybar/autostart.sh
- ~/.config/polybar/*.sh  (all scripts)
- ~/.config/rofi/powermenu.sh
- ~/.config/autostart/polybar.desktop

AUDIO SINKS (lu47 system specific):
- Speakers: alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio__sink
- Headset:  alsa_output.usb-Corsair_CORSAIR_HS80_RGB_Wireless_Gaming_Receiver_...

NOTE: On a new system run 02_recon.sh first to get correct
interface names, audio sinks and sensor paths before deploying.

# POLYBAR CYBERPUNK HUD — V2

## What's new in V2
- Weather switched from wttr.in to Open-Meteo (no API key, free forever)
- Klipper/OctoPrint printer status module via Moonraker API
- Spotify right-click notification (full artist + title via dunst)
- Spotify shows artist + title (truncated to 20 chars)
- Light control modules removed (Tuya cloud expired, local API blocked)

## Monitors
- DP-2 → Primary landscape 2560x1440
- HDMI-0 → Portrait 1080x1920 display only

## Install
1. `sudo apt install btop copyq dunst redshift xterm polybar rofi playerctl xdotool wmctrl bluez blueman gnome-screenshot nemo curl lm-sensors pulseaudio-utils tinytuya`
2. Install JetBrainsMono Nerd Font to ~/.local/share/fonts/
3. `chmod +x 01_cleanup.sh 02_recon.sh 03_install.sh`
4. `./01_cleanup.sh`
5. `./02_recon.sh`
6. `./03_install.sh`

## Notes
- Klipper IP hardcoded to YOUR_KLIPPER_IP — update klipper.sh if different
- Audio sinks hardcoded for Corsair HS80 + Generic USB speakers — update audio_switch.sh if different
- Network interface hardcoded to YOUR_NETWORK_INTERFACE — update config.ini if different

# POLYBAR CYBERPUNK HUD

> Cyberpunk-themed dual-monitor Polybar HUD for Linux Mint Cinnamon — neon cyan/green aesthetic with system monitoring, media controls, smart notifications and one-click power management.

---

## PREVIEW

> Screenshot coming soon — portrait display-only monitor on the left, primary HUD on top, workspace switcher on the bottom.

---

## FEATURES

### Primary Bar (DP-2 — Top)
| Zone | Modules |
|------|---------|
| Left | System tray, App launcher, Clipboard manager, Night mode, Quick notes, File manager, Terminal, Screenshot, Spotify controls |
| Center | Clock |
| Right | Weather, Network speed, Mic toggle, Volume, Audio switch, DND traffic light, NUKE, Power menu |

### Workspace Bar (DP-2 — Bottom)
- Workspace circles centered, clickable, scrollable

### Portrait Bar (HDMI-0 — Display only)
- CPU %, CPU temp, RAM, Disk usage, Date/time, Uptime, Local IP, Active window title

---

## MODULES

| Module | Description | Click |
|--------|-------------|-------|
| MENU | Rofi app launcher | Opens rofi drun |
| COPYBIN | Clipboard history | Opens copyq picker |
| NM | Night mode / redshift | Toggle on/off |
| QUICKNOTE | Floating scratchpad | Opens xterm with ~/notes.txt |
| FILES | File manager | Opens nemo /home |
| TERMINAL | Terminal emulator | Opens gnome-terminal |
| SS | Screenshot | Opens gnome-screenshot GUI |
| ◀ title ▶ | Spotify controller | Click title=pause, ◀▶=skip |
| Weather | wttr.in Bogotá | Display only, color coded |
| NET | Network speed | ↓ down ↑ up |
| MIC | Microphone toggle | Blue=on Red=muted |
| VOL | Volume % | Click=mute, Scroll=±5% |
| AUDIO | Headset/Speakers switch | Click to toggle |
| DND | Do not disturb | 🟢 on / 🟡 silent / 🔴 off |
| NUKE | Force kill focused window | Session-aware confirm |
| PWR | Power menu | Shutdown/Reboot/Logout/BT |

---

## REQUIREMENTS

```bash
sudo apt install polybar rofi btop copyq dunst redshift xterm \
    playerctl xdotool wmctrl bluez blueman gnome-screenshot \
    nemo curl lm-sensors pulseaudio-utils
```

**Font:** [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip)

```bash
mkdir -p ~/.local/share/fonts
unzip JetBrainsMono.zip -d ~/.local/share/fonts
fc-cache -fv
```

---

## INSTALL

```bash
# 1. Clone the repo
git clone https://github.com/lualducor/polybar-cyberpunk-hud.git
cd polybar-cyberpunk-hud

# 2. Make scripts executable
chmod +x 01_cleanup.sh 02_recon.sh 03_install.sh

# 3. Clean your environment
./01_cleanup.sh

# 4. Run system recon — verify all tools are found
./02_recon.sh
cat /tmp/polybar_recon.txt

# 5. Install
./03_install.sh
```

> ⚠️ **Important:** On a new system, run `02_recon.sh` first and check the output. You may need to update the following in `config.ini` and `audio_switch.sh`:
> - Network interface name (default: `eno2`)
> - Audio sink names for speakers and headset
> - CPU sensor path in `cpu_temp.sh`

---

## MONITOR SETUP

This config is built for:
- **DP-2** — Primary landscape monitor (2560x1440)
- **HDMI-0** — Secondary portrait monitor (1080x1920, rotated left)

To adapt for your monitors replace the monitor names in `config.ini`:
```ini
[bar/right]
monitor = DP-2    # ← change to your primary monitor

[bar/right-bottom]
monitor = DP-2    # ← same as primary

[bar/left]
monitor = HDMI-0  # ← change to your secondary monitor
width   = 1080    # ← match your secondary monitor's width
```

Run `xrandr --query | grep " connected"` to get your monitor names.

---

## FILE STRUCTURE

```
polybar-cyberpunk-hud/
├── config.ini          # Main Polybar config (3 bars)
├── launch.sh           # Starts all bars
├── autostart.sh        # Master boot sequence
├── powermenu.sh        # Rofi power menu → ~/.config/rofi/
├── dnd.sh              # DND traffic light
├── weather.sh          # wttr.in weather parser
├── audio_switch.sh     # Headset/speaker toggle
├── nuke.sh             # Session-aware process killer
├── night_mode.sh       # Redshift toggle
├── quick_notes.sh      # Floating scratchpad
├── spotify.sh          # Spotify title fetcher
├── mic.sh              # Mic mute toggle
├── cpu_temp.sh         # CPU temperature with colors
├── uptime.sh           # Colorized uptime
├── local_ip.sh         # Local IP address
├── 01_cleanup.sh       # Environment cleanup utility
├── 02_recon.sh         # System recon utility
└── 03_install.sh       # Automated installer
```

---

## COLOR SCHEME

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#0d1117` | Bar background |
| Primary / Cyan | `#00f3ff` | Active elements, separators |
| Secondary / Green | `#39ff14` | Interactive modules |
| Alert / Red | `#f7768e` | Warnings, PWR, NUKE |
| Warn / Yellow | `#dfff00` | Caution states |
| Disabled | `#444444` | Inactive elements |

---

## WEATHER CONDITIONS

| Color | Conditions |
|-------|-----------|
| 🟢 Green | Clear, Sunny, Cloudy, Overcast |
| 🟡 Yellow | Drizzle, Showers, Mist, Fog, Windy |
| 🔴 Red | Rain, Thunderstorm, Snow, Hail, Sleet |

---

## KNOWN ISSUES

- Portrait monitor requires `override-redirect = true` due to a Polybar bug with rotated displays — clicks do not register on the portrait bar (by design, display only)
- `width = 100%` breaks on rotated monitors — hardcoded to `1080` for HDMI-0
- wttr.in weather API occasionally goes down — shows `WTHR N/A` when unavailable

---

## VERSION

**v1.0** — Initial release

---

## LICENSE

MIT — do whatever you want with it.

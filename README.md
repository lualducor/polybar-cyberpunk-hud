# Polybar Cyberpunk HUD — V3

A cyberpunk-styled dual-monitor Polybar setup for Linux Mint / Cinnamon with AI cost tracking, Klipper 3D printer monitoring, Spotify controls, and a full suite of system modules.

---

## What's New in V3

- **AI budget modules** — live cost display for OpenAI (GPT), Anthropic (Claude), and Gemini directly in the bar
  - Session and weekly spend with color-coded budget warnings
  - Left-click: open a terminal with that AI CLI (codex / claude / gemini)
  - Middle-click: reset session counter · Right-click: force refresh
- **`ai_budget.py`** — reads costs from API billing endpoints and local Claude/Codex session logs, no extra tools required
- **`ai_cli_launcher.sh`** — configurable working directory via `AI_WORKDIR` env var
- **`update_gemini_budget.py`** — CLI helper to update Gemini billing JSON
- **`identify_audio_sinks.sh`** — helper to discover PulseAudio sink names
- **`setup.sh`** — interactive one-command installer: patches network interface, Moonraker URL, and AI workdir for any system

## What's New in V2

- Weather switched from wttr.in to Open-Meteo (no API key, free forever)
- Klipper/Moonraker printer status module (progress %, ETA, state)
- Spotify right-click notification (full artist + title via dunst)
- Light control modules removed (Tuya cloud expired, local API blocked)

---

## Modules

| Module | Description |
|--------|-------------|
| `ai-budget-gpt` | OpenAI spend — session % / weekly % |
| `ai-budget-claude` | Anthropic spend — session % / weekly % |
| `ai-launch-gemini` | Gemini launcher (click to open terminal) |
| `klipper` | Moonraker print status — state, progress, ETA |
| `weather` | Temperature + condition via Open-Meteo (no key) |
| `spotify-*` | Prev / play-pause / next + right-click dunst notification |
| `nightmode` | Toggle redshift |
| `dnd` | Toggle dunst Do Not Disturb |
| `mic` | Toggle microphone mute |
| `pulseaudio` | Volume — scroll to adjust, click to mute |
| `audio-switch` | Toggle between two audio sinks |
| `network` | Download / upload speed |
| `cpu-numeric` | CPU % — click to open btop |
| `cpu-temp` | CPU temperature via lm-sensors |
| `memory` | RAM used — click to open btop |
| `filesystem` | Disk usage % |
| `local-ip` | Local IP address |
| `uptime` | System uptime |
| `xworkspaces` | Workspace switcher |
| `xwindow` | Active window title |
| `clipboard` | Open CopyQ clipboard manager |
| `rofi-menu` | App launcher (rofi) |
| `nuke` | Kill all windows on current workspace |
| `powermenu` | Rofi power menu (shutdown / reboot / lock) |

---

## Requirements

```bash
sudo apt install polybar rofi playerctl dunst btop copyq redshift \
  xdotool wmctrl bluez blueman gnome-screenshot nemo curl \
  lm-sensors pulseaudio-utils python3
```

**Font:** [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) → install to `~/.local/share/fonts/`

**Optional (AI modules):**
- OpenAI: admin API key with billing read access
- Anthropic: admin API key — or just works from local `~/.claude/projects/` logs
- Gemini: Cloud Billing budget JSON via `update_gemini_budget.py`

---

## Install

### Option A — Interactive setup (recommended)

```bash
git clone https://github.com/lualducor/polybar-cyberpunk-hud
cd polybar-cyberpunk-hud
bash setup.sh
```

`setup.sh` will ask for your network interface, Moonraker URL, and AI working directory, then copy and patch all files into `~/.config/polybar/`.

### Option B — Manual install

```bash
# 1. Wipe old config, back it up, clear cache
bash 01_cleanup.sh

# 2. Scan your system — detects interfaces, sinks, monitors, missing tools
bash 02_recon.sh

# 3. Install files, set permissions, configure autostart
bash 03_install.sh
```

After install, patch the system-specific values (see Configuration below), then launch:

```bash
bash ~/.config/polybar/launch.sh
```

---

## Configuration

After install, edit files in `~/.config/polybar/`:

| File | What to set |
|------|-------------|
| `config.ini` | `YOUR_NET_IFACE` → your interface (`ip link show`) |
| `config.ini` | `YOUR_KLIPPER_IP` → your Moonraker IP/host |
| `config.ini` | Monitor names in `[bar/right]`, `[bar/left]`, `[bar/right-bottom]` (`xrandr --listmonitors`) |
| `klipper.sh` | `MOONRAKER_URL` env var, or edit the fallback default |
| `audio_switch.sh` | Your two PulseAudio sink names (`pactl list short sinks` or run `identify_audio_sinks.sh`) |
| `ai_budget.env` | Copy from `ai_budget.env.example`, fill in API keys and budget amounts |

### AI Budget Setup

```bash
cp ~/.config/polybar/ai_budget.env.example ~/.config/polybar/ai_budget.env
# Edit with your keys:
nano ~/.config/polybar/ai_budget.env
```

Key variables:

```bash
OPENAI_ADMIN_KEY=sk-admin-...       # OpenAI admin key (billing read)
ANTHROPIC_ADMIN_API_KEY=sk-ant-...  # Anthropic admin key (or leave blank — reads local logs)

OPENAI_WEEKLY_BUDGET_USD=25
OPENAI_SESSION_BUDGET_USD=5
ANTHROPIC_WEEKLY_BUDGET_USD=25
ANTHROPIC_SESSION_BUDGET_USD=5
```

> **Anthropic without an API key:** `ai_budget.py` will automatically scan `~/.claude/projects/` and estimate costs from local session logs.

### Klipper / Moonraker Setup

Set `MOONRAKER_URL` in your environment (e.g. in `~/.bashrc`):

```bash
export MOONRAKER_URL=http://192.168.1.100:7125
```

Or edit the fallback directly in `~/.config/polybar/klipper.sh`.

---

## Bar Layout

```
[bar/right]      — primary monitor, top
LEFT:   tray | menu | clipboard | nightmode | quicknotes | files | terminal | screenshot | spotify
CENTER: clock
RIGHT:  GPT budget | Gemini | Claude budget | klipper | weather | network | mic | volume | audio-switch | dnd | nuke | power

[bar/right-bottom] — primary monitor, bottom
CENTER: workspaces

[bar/left]       — secondary portrait monitor
LEFT:   cpu | temp | ram | disk | date | uptime | ip | window title
```

---

## File Reference

```
config.ini              — main polybar config (all bars and modules)
launch.sh               — start/restart all bars
autostart.sh            — called by the .desktop autostart entry
ai_budget.py            — AI cost tracker (OpenAI, Anthropic, Gemini)
ai_budget.env.example   — template for API keys and budgets
update_gemini_budget.py — update Gemini billing JSON from CLI
ai_cli_launcher.sh      — open kitty terminal with codex/claude/gemini
klipper.sh              — Moonraker print status
weather.sh              — Open-Meteo weather
audio_switch.sh         — toggle between two audio sinks
identify_audio_sinks.sh — list PulseAudio sinks for config
spotify.sh              — Spotify title display
spotify_ctrl.sh         — Spotify prev/play-pause/next
spotify_notify.sh       — dunst full track notification
night_mode.sh           — redshift toggle
dnd.sh                  — dunst Do Not Disturb toggle
mic.sh                  — microphone mute toggle
nuke.sh                 — kill all windows on workspace
quick_notes.sh          — quick note launcher
cpu_temp.sh             — CPU temperature via sensors
uptime.sh               — system uptime
local_ip.sh             — local IP address
01_cleanup.sh           — wipe old config + backup
02_recon.sh             — system scan (interfaces, sinks, monitors, tools)
03_install.sh           — full install + autostart setup
setup.sh                — interactive installer (patches system-specific values)
rofi/powermenu.sh       — rofi power menu
```

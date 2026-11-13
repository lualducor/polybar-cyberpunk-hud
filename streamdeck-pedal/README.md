# Stream Deck Pedal on Linux

## Install from this repository

From the repository root, after installing the Polybar files with setup.sh:

```bash
mkdir -p ~/.local/share/streamdeck-pedal ~/.config/systemd/user
cp streamdeck-pedal/pedal.py streamdeck-pedal/profiles.json ~/.local/share/streamdeck-pedal/
python3 -m venv ~/.local/share/streamdeck-pedal/venv
~/.local/share/streamdeck-pedal/venv/bin/pip install evdev streamdeck
cp streamdeck-pedal/streamdeck-pedal.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now streamdeck-pedal.service
```

The native HIDAPI library is required by python-elgato-streamdeck (on Ubuntu,
the package is libhidapi-libusb0). The service user needs access to the Elgato
HID device, /dev/uinput, and physical keyboard input devices. The original
machine already has these permissions; provisioning permissions on a fresh
machine is separate from installing the files. Do not copy the virtual
environment between machines. The bar shows OFF until the service runs.

The main display's lower Polybar has a clickable `PEDAL: 0` control between
FULL and workspace 1. Click it, choose a profile, and press Enter. Escape
cancels. The active profile is marked with `*` in the menu. Choices persist
across logins. The label refreshes every two seconds; OFF means no service
process was found, not a USB connectivity check.

## Profiles

| Profile | Left pedal (0) | Middle pedal (1) | Right pedal (2) |
| --- | --- | --- | --- |
| 0 | Scroll down | Enter | Scroll up |
| 1 | Scroll down | Microphone mute/restore | Scroll up |
| 2 | Previous window | Open picker / confirm | Next window |
| 3 | Volume down 5% | Toggle output mute | Volume up 5% |
| 4 | Previous track | Play/pause | Next track |
| 5 | Browser back | Focus address bar | Browser forward |
| 6 | Copy | Select all | Paste |

Profile 0 is the renamed default. Scrolling directions preserve the original
configuration: left emits REL_WHEEL -1, right +1. Scroll and volume repeat
while held (350 ms delay, then every 120 ms); keyboard shortcuts fire once.

Profile 1 mutes all non-monitor microphone sources, saving each prior state.
The next press restores those states. If all microphones were already muted,
a press unmutes them all. The saved snapshot exists only until service restart
or profile change; switching profiles does not automatically unmute microphones.

Profile 2: press the middle pedal to open the desktop's Alt+Tab switcher.
Use left/right to move backward/forward, then press middle again to confirm.
Outside pedals do nothing until the picker is open and repeat while held.
Alt is released on service stop, error, or disconnect. Keyboard Escape can
cancel the desktop picker; press middle afterward to release the held Alt.
This relies on the desktop's Alt+Tab binding. The first middle press selects
the next window as ordinary Alt+Tab does.

Profile 3 targets the default output using pactl. Profile 4 uses desktop
media keys. Profiles 5–6 send shortcuts to the focused application.
Profile 6 uses Ctrl+C/A/V; terminal
emulators commonly require Ctrl+Shift+C/V instead, and Ctrl+C interrupts a
running terminal command.

## Configuration and maintenance

### Hold-key switching

Hold Right Ctrl and press left for the previous profile, right for the next, or
middle to return to profile 0. Profiles wrap between 0 and 6. Each pedal
press switches once; release it before pressing again. Changes persist and
the Polybar label updates within two seconds. Normal pedal actions are
suppressed while Right Ctrl is held. Right Ctrl still reaches the focused
application; pressing other keyboard keys with it can trigger Ctrl shortcuts.

The service queries the configured key's current state on accessible physical
keyboards through evdev; it does not record keyboard events or grab the
keyboard. Existing membership in the input group supplies device access.
Keyboard reconnects are detected within five seconds. To use another key,
set `Environment=STREAMDECK_PEDAL_MODIFIER=KEY_RIGHTCTRL` in a service drop-in,
run `systemctl --user daemon-reload`, and restart the pedal service.

Switching uses the same helper as Polybar and restarts the service. A held
pedal is ignored until released after restart, preventing accidental actions
or repeated switches. Switching out of the window picker releases Alt.

- Program: `~/.local/share/streamdeck-pedal/pedal.py`
- Profile definitions: `~/.local/share/streamdeck-pedal/profiles.json`
- Virtual environment: `~/.local/share/streamdeck-pedal/venv`
- User service: `~/.config/systemd/user/streamdeck-pedal.service`
- Persistent selected profile: `~/.config/systemd/user/streamdeck-pedal.service.d/99-polybar-profile.conf`
- Polybar helper: `~/.config/polybar/pedal_profile.py`
- Polybar module: `[module/pedal-profile]` in `~/.config/polybar/config.ini`

The service reads Elgato USB vendor 0x0FD9/product 0x0086 through
python-elgato-streamdeck and creates the virtual evdev/uinput device
`Stream Deck Pedal Scroll`. Its name is retained for compatibility.
The user service is enabled at login and reconnects after USB disconnection.
The existing USB/uinput permissions and virtual environment must be retained.

Switch or inspect from a terminal:

```bash
python3 ~/.config/polybar/pedal_profile.py set 2
python3 ~/.config/polybar/pedal_profile.py status
journalctl --user -u streamdeck-pedal.service -n 30 --no-pager
```

The helper writes the selected environment variable, reloads systemd, and
restarts only the pedal service. The override takes precedence over the main
unit's Environment entry. Without an override/environment setting, profile 0
is used. The bar reads the running process's environment rather than the
selected file, so a pending configuration change is not reported as active.

## Add or change profiles

Edit profiles.json. Each named profile has a description and a buttons object
containing exactly keys `0`, `1`, and `2`. Names use letters, digits, hyphens,
or underscores. Available action objects:

```json
{"action": "none"}
{"action": "scroll", "direction": -1}
{"action": "key", "key": "KEY_ENTER"}
{"action": "chord", "keys": ["KEY_LEFTCTRL", "KEY_S"]}
{"action": "mic"}
{"action": "volume", "amount": "+5%"}
{"action": "audio_mute"}
{"action": "window", "direction": 0}
```

Key names come from evdev.ecodes. Chord keys are pressed in order and released
in reverse order. Window direction -1/1 navigates; 0 opens/confirms.
Descriptions appear automatically in the Polybar picker. After editing the
active profile, reselect it or run:

```bash
systemctl --user restart streamdeck-pedal.service
```

Invalid configuration appears in the service journal. Profiles load at startup,
so editing JSON alone does not change the running mapping.

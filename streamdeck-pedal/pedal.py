#!/usr/bin/env python3
"""Map the Stream Deck Pedal to scrolling and Enter."""

import signal
import json
import os
import subprocess
import time
from pathlib import Path

from evdev import InputDevice, UInput, ecodes, list_devices
from StreamDeck.DeviceManager import DeviceManager


VENDOR_ID = 0x0FD9
PRODUCT_ID = 0x0086
HOLD_DELAY = 0.35
REPEAT_INTERVAL = 0.12
CONFIG_PATH = Path(__file__).with_name("profiles.json")
PROFILE_NAME = os.environ.get("STREAMDECK_PEDAL_PROFILE", "0")
stop = False
switching = False
muted_snapshot = None
PROFILE_MODIFIER = os.environ.get("STREAMDECK_PEDAL_MODIFIER", "KEY_RIGHTCTRL")
PROFILE_HELPER = Path.home() / ".config/polybar/pedal_profile.py"


class ProfileModifier:
    """Query only the configured key's held state; never capture typed text."""

    def __init__(self):
        self.devices = []
        self.next_scan = 0
        self.key = getattr(ecodes, PROFILE_MODIFIER)

    def held(self):
        if time.monotonic() >= self.next_scan:
            self.close()
            for path in list_devices():
                device = None
                try:
                    device = InputDevice(path)
                    sysfs = (Path("/sys/class/input") / Path(path).name / "device").resolve()
                    if "/devices/virtual/" not in str(sysfs) and self.key in device.capabilities().get(ecodes.EV_KEY, []):
                        self.devices.append(device)
                    else:
                        device.close()
                except OSError:
                    if device is not None:
                        device.close()
            self.next_scan = time.monotonic() + 5
        held = False
        for device in self.devices:
            try:
                held = self.key in device.active_keys() or held
            except OSError:
                self.next_scan = 0
        return held

    def close(self):
        for device in self.devices:
            device.close()
        self.devices = []


def adjacent_profile(index):
    names = list(json.loads(CONFIG_PATH.read_text()))
    if index == 1:
        return "0"
    return names[(names.index(PROFILE_NAME) + (-1 if index == 0 else 1)) % len(names)]


def stop_service(_signum, _frame):
    global stop
    stop = True


signal.signal(signal.SIGTERM, stop_service)
signal.signal(signal.SIGINT, stop_service)


def find_pedal():
    for device in DeviceManager().enumerate():
        if device.vendor_id() == VENDOR_ID and device.product_id() == PRODUCT_ID:
            return device
    return None


def load_profile():
    profiles = json.loads(CONFIG_PATH.read_text())
    profile = profiles[PROFILE_NAME]
    buttons = profile["buttons"]
    if set(buttons) != {"0", "1", "2"}:
        raise ValueError("profile must define buttons 0, 1, and 2")
    for action in buttons.values():
        if action["action"] not in {"none", "scroll", "key", "chord", "mic", "volume", "audio_mute", "window"}:
            raise ValueError(f"Unknown action: {action}")
        for name in action.get("keys", [action["key"]] if "key" in action else []):
            if not name.startswith("KEY_") or not isinstance(getattr(ecodes, name, None), int):
                raise ValueError(f"Invalid key: {name}")
    return profile


def chord(wheel, names):
    keys = [getattr(ecodes, name) for name in names]
    try:
        for key in keys:
            wheel.write(ecodes.EV_KEY, key, 1)
            wheel.syn()
    finally:
        for key in reversed(keys):
            wheel.write(ecodes.EV_KEY, key, 0)
            wheel.syn()


def pactl(*args):
    return subprocess.run(["pactl", *args], capture_output=True, text=True,
                          check=True, timeout=3).stdout


def toggle_microphone():
    global muted_snapshot
    microphones = [row["name"] for row in json.loads(pactl("--format=json", "list", "sources"))
                   if not row["name"].endswith(".monitor")]
    if not microphones:
        return
    if muted_snapshot is not None:
        for name, muted in muted_snapshot.items():
            if name in microphones:
                pactl("set-source-mute", name, "1" if muted else "0")
        muted_snapshot = None
        return
    states = {name: pactl("get-source-mute", name).strip().endswith("yes") for name in microphones}
    for name in microphones:
        pactl("set-source-mute", name, "0" if all(states.values()) else "1")
    if not all(states.values()):
        muted_snapshot = states


def release_switcher(wheel):
    global switching
    if switching:
        wheel.write(ecodes.EV_KEY, ecodes.KEY_LEFTALT, 0)
        wheel.syn()
        switching = False


def emit_action(wheel, action):
    global switching
    kind = action["action"]
    if kind == "window":
        direction = action["direction"]
        if direction == 0:
            if switching:
                release_switcher(wheel)
            else:
                wheel.write(ecodes.EV_KEY, ecodes.KEY_LEFTALT, 1)
                wheel.syn()
                switching = True
                chord(wheel, ["KEY_TAB"])
        elif switching:
            chord(wheel, ["KEY_LEFTSHIFT", "KEY_TAB"] if direction < 0 else ["KEY_TAB"])
        return
    if kind == "mic":
        toggle_microphone()
        return
    if kind == "volume":
        pactl("set-sink-volume", "@DEFAULT_SINK@", action["amount"])
        return
    if kind == "audio_mute":
        pactl("set-sink-mute", "@DEFAULT_SINK@", "toggle")
        return
    if kind == "chord":
        chord(wheel, action["keys"])
        return
    if action["action"] == "none":
        return
    if action["action"] == "scroll":
        wheel.write(ecodes.EV_REL, ecodes.REL_WHEEL, int(action["direction"]))
        wheel.syn()
        return
    if action["action"] == "key":
        key = getattr(ecodes, action["key"])
        wheel.write(ecodes.EV_KEY, key, 1)
        wheel.syn()
        wheel.write(ecodes.EV_KEY, key, 0)
        wheel.syn()
        return
    raise ValueError(f"unknown pedal action: {action['action']}")


def action_repeats(action):
    return action["action"] in {"scroll", "volume"} or (
        action["action"] == "window" and action["direction"] != 0)


def run_pedal(deck, wheel, profile):
    previous = [False, False, False]
    next_repeat = [0.0, 0.0, 0.0]
    actions = [profile["buttons"][str(index)] for index in range(3)]
    deck.open()
    modifier = ProfileModifier()
    # A profile restart must not reinterpret the pedal that triggered it.
    blocked = any(deck.key_states())
    changing_profile = None
    print(f"Stream Deck Pedal connected (profile: {PROFILE_NAME})", flush=True)
    try:
        while not stop and deck.connected():
            states = deck.key_states()
            now = time.monotonic()
            if blocked:
                blocked = any(states)
                previous = list(states)
                time.sleep(0.02)
                continue
            if changing_profile is not None:
                if changing_profile.poll() is None:
                    time.sleep(0.02)
                    continue
                changing_profile = None
                blocked = True
                continue
            if modifier.held():
                release_switcher(wheel)
                for index in range(3):
                    if states[index] and not previous[index]:
                        target = adjacent_profile(index)
                        if target != PROFILE_NAME:
                            changing_profile = subprocess.Popen(
                                ["systemd-run", "--user", "--collect", "--quiet", "--wait",
                                 "/usr/bin/python3", str(PROFILE_HELPER), "set", target])
                        break
                blocked = any(states)
                previous = list(states)
                time.sleep(0.02)
                continue
            for index, action in enumerate(actions):
                if states[index] and not previous[index]:
                    emit_action(wheel, action)
                    if action_repeats(action):
                        next_repeat[index] = now + HOLD_DELAY
                elif states[index] and action_repeats(action) and now >= next_repeat[index]:
                    emit_action(wheel, action)
                    next_repeat[index] = now + REPEAT_INTERVAL
            previous = list(states)
            time.sleep(0.02)
    finally:
        modifier.close()
        release_switcher(wheel)
        deck.close()
        print("Stream Deck Pedal disconnected", flush=True)


def main():
    profile = load_profile()
    capabilities = {
        ecodes.EV_KEY: sorted({ecodes.BTN_LEFT, ecodes.KEY_LEFTALT,
                             ecodes.KEY_LEFTSHIFT, ecodes.KEY_TAB} | {
            getattr(ecodes, key)
            for action in profile["buttons"].values()
            for key in action.get("keys", [action["key"]] if "key" in action else [])
        }),
        ecodes.EV_REL: [ecodes.REL_X, ecodes.REL_Y, ecodes.REL_WHEEL],
    }
    with UInput(capabilities, name="Stream Deck Pedal Scroll") as wheel:
        while not stop:
            deck = find_pedal()
            if deck is None:
                time.sleep(2)
                continue
            try:
                run_pedal(deck, wheel, profile)
            except Exception as exc:
                print(f"Pedal error: {exc}", flush=True)
            if not stop:
                time.sleep(2)


if __name__ == "__main__":
    main()

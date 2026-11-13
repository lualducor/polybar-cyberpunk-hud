#!/usr/bin/env python3
"""Polybar status and persistent profile picker for the pedal user service."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys

SERVICE = "streamdeck-pedal.service"
PROFILES = Path.home() / ".local/share/streamdeck-pedal/profiles.json"
OVERRIDE = Path.home() / ".config/systemd/user/streamdeck-pedal.service.d/99-polybar-profile.conf"


def systemctl(*args):
    return subprocess.run(["systemctl", "--user", *args],
                          capture_output=True, text=True, check=True)


def active_profile():
    try:
        pid = int(systemctl("show", SERVICE, "--property=MainPID", "--value").stdout.strip())
        if not pid:
            return None
        environment = Path(f"/proc/{pid}/environ").read_bytes().split(b"\0")
        for item in environment:
            if item.startswith(b"STREAMDECK_PEDAL_PROFILE="):
                return item.split(b"=", 1)[1].decode()
        return "0"
    except (OSError, ValueError, subprocess.CalledProcessError):
        return None


def select_profile(name):
    profiles = json.loads(PROFILES.read_text())
    if name not in profiles or not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        raise ValueError("Unknown profile or unsupported profile name")
    OVERRIDE.parent.mkdir(parents=True, exist_ok=True)
    temporary = OVERRIDE.with_suffix(".tmp")
    temporary.write_text(f"[Service]\nEnvironment=STREAMDECK_PEDAL_PROFILE={name}\n")
    os.replace(temporary, OVERRIDE)
    systemctl("daemon-reload")
    systemctl("restart", SERVICE)


def menu():
    profiles = json.loads(PROFILES.read_text())
    names = list(profiles)
    active = active_profile()
    rows = [f"{'* ' if name == active else '  '}{name} — {profiles[name].get('description', '')}"
            for name in names]
    result = subprocess.run(
        ["rofi", "-dmenu", "-i", "-no-custom", "-format", "i", "-p", "Pedal profile",
         "-mesg", f"Active: {active or 'service stopped'}", "-selected-row",
         str(names.index(active) if active in names else 0)],
        input="\n".join(rows), capture_output=True, text=True)
    if result.returncode == 0:
        select_profile(names[int(result.stdout.strip())])


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "status":
        name = active_profile()
        # Prevent profile names from injecting Polybar formatting.
        print("PEDAL: " + (name.replace("%", "") if name else "OFF"))
    elif command == "menu":
        menu()
    elif command == "set" and len(sys.argv) == 3:
        select_profile(sys.argv[2])
    else:
        raise ValueError("Usage: pedal_profile.py status|menu|set PROFILE")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        subprocess.run(["notify-send", "Pedal profile failed", str(exc)], check=False)
        print(str(exc), file=sys.stderr)
        sys.exit(1)

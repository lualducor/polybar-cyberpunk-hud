#!/usr/bin/env python3
"""Polybar client for the Cyberpunk HUD GNOME Shell bridge."""

import json
import sys

from gi.repository import Gio, GLib

BUS_NAME = "com.openmirai.CyberpunkHud"
OBJECT_PATH = "/com/openmirai/CyberpunkHud"
INTERFACE = "com.openmirai.CyberpunkHud"


def call(method, parameters=None):
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    result = bus.call_sync(
        BUS_NAME,
        OBJECT_PATH,
        INTERFACE,
        method,
        parameters,
        None,
        Gio.DBusCallFlags.NONE,
        1000,
        None,
    )
    return result.unpack()[0]


def status():
    return json.loads(call("GetStatus"))


def render_workspaces(data):
    active = data["workspace"]
    count = data["workspaces"]
    parts = []
    for index in range(count):
        color = "#00f3ff" if index == active else "#39ff14"
        action = f"python3 ~/.config/polybar/gnome_hud.py action workspace:{index}"
        parts.append(f"%{{A1:{action}:}}%{{F{color}}} {index + 1} %{{F-}}%{{A}}")
    return "".join(parts) or "%{F#444444} DESKTOP %{F-}"


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "title"
    try:
        if command == "action":
            if len(sys.argv) != 3:
                raise SystemExit("usage: gnome_hud.py action ACTION")
            success = call("Action", GLib.Variant("(s)", (sys.argv[2],)))
            raise SystemExit(0 if success else 1)

        data = status()
        if command == "title":
            title = data.get("title") or "DESKTOP"
            print(title[:20] + ("..." if len(title) > 20 else ""))
        elif command == "workspaces":
            print(render_workspaces(data))
        else:
            raise SystemExit(f"unknown command: {command}")
    except GLib.Error:
        print("GNOME BRIDGE OFFLINE" if command != "action" else "", end="\n")
        raise SystemExit(1)


if __name__ == "__main__":
    main()

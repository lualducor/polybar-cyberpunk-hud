#!/usr/bin/env python3
# ============================================================
# YEELIGHT LOCAL LAN TOGGLE
# Controls lights via local network — no cloud needed
# Usage: yeelight_toggle.py <status|toggle> <ip> <label>
# ============================================================

import sys
import socket
import json
import os

STATE_DIR = "/tmp/yeelight_states"
os.makedirs(STATE_DIR, exist_ok=True)

def send_command(ip, command):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        sock.connect((ip, 55443))
        msg = json.dumps(command) + "\r\n"
        sock.sendall(msg.encode())
        response = sock.recv(1024).decode()
        sock.close()
        return json.loads(response)
    except Exception:
        return None

def toggle(ip, label):
    state_file = f"{STATE_DIR}/{ip.replace('.', '_')}"
    if os.path.exists(state_file):
        with open(state_file) as f:
            current = f.read().strip()
    else:
        current = "off"

    new_state = "on" if current == "off" else "off"

    cmd = {
        "id": 1,
        "method": "set_power",
        "params": [new_state, "smooth", 500]
    }
    result = send_command(ip, cmd)
    if result and result.get("result") == ["ok"]:
        with open(state_file, "w") as f:
            f.write(new_state)

def status(ip, label):
    state_file = f"{STATE_DIR}/{ip.replace('.', '_')}"
    if os.path.exists(state_file):
        with open(state_file) as f:
            state = f.read().strip()
    else:
        state = "off"

    if state == "on":
        print(f"%{{F#dfff00}} {label} %{{F-}}")
    else:
        print(f"%{{F#00f3ff}} {label} %{{F-}}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: yeelight_toggle.py <status|toggle> <ip> <label>")
        sys.exit(1)

    action = sys.argv[1]
    ip     = sys.argv[2]
    label  = sys.argv[3]

    if action == "toggle":
        toggle(ip, label)
    elif action == "status":
        status(ip, label)

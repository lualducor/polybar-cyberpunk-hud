#!/usr/bin/env python3
# ============================================================
# TUYA LIGHT TOGGLE
# Controls SATOSHI and BAÑO via Tuya Cloud API
# Usage: tuya_toggle.py <device_id> <label>
# ============================================================

import sys
import time
import hmac
import hashlib
import requests
import json
import os

# Tuya credentials
CLIENT_ID     = "YOUR_TUYA_CLIENT_ID"
CLIENT_SECRET = "YOUR_TUYA_CLIENT_SECRET"
BASE_URL      = "https://openapi.tuyaXX.com"  # Change XX to your region: us, eu, cn, in

# State file directory
STATE_DIR = "/tmp/tuya_states"
os.makedirs(STATE_DIR, exist_ok=True)

def get_token():
    t = str(int(time.time() * 1000))
    msg = CLIENT_ID + t
    sign = hmac.new(CLIENT_SECRET.encode(), msg.encode(), hashlib.sha256).hexdigest().upper()
    headers = {
        "client_id": CLIENT_ID,
        "sign": sign,
        "t": t,
        "sign_method": "HMAC-SHA256"
    }
    r = requests.get(f"{BASE_URL}/v1.0/token?grant_type=1", headers=headers)
    return r.json()["result"]["access_token"]

def sign_request(token, method, path, body=""):
    t = str(int(time.time() * 1000))
    content_hash = hashlib.sha256(body.encode()).hexdigest()
    str_to_sign = "\n".join([method, content_hash, "", path])
    msg = CLIENT_ID + token + t + str_to_sign
    sign = hmac.new(CLIENT_SECRET.encode(), msg.encode(), hashlib.sha256).hexdigest().upper()
    return {
        "client_id": CLIENT_ID,
        "access_token": token,
        "sign": sign,
        "t": t,
        "sign_method": "HMAC-SHA256",
        "Content-Type": "application/json"
    }

def toggle(device_id, label):
    state_file = f"{STATE_DIR}/{device_id}"
    # Read current blind state
    if os.path.exists(state_file):
        with open(state_file) as f:
            current = f.read().strip()
    else:
        current = "off"

    new_state = "false" if current == "on" else "true"

    try:
        token = get_token()
        path = f"/v1.0/devices/{device_id}/commands"
        body = json.dumps({"commands": [{"code": "switch_led", "value": new_state == "true"}]})
        headers = sign_request(token, "POST", path, body)
        r = requests.post(f"{BASE_URL}{path}", headers=headers, data=body)
        result = r.json()
        if result.get("success"):
            new = "on" if new_state == "true" else "off"
            with open(state_file, "w") as f:
                f.write(new)
    except Exception:
        pass

def status(device_id, label):
    state_file = f"{STATE_DIR}/{device_id}"
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
        print("Usage: tuya_toggle.py <status|toggle> <device_id> <label>")
        sys.exit(1)

    action    = sys.argv[1]
    device_id = sys.argv[2]
    label     = sys.argv[3]

    if action == "toggle":
        toggle(device_id, label)
    elif action == "status":
        status(device_id, label)

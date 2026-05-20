#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = SCRIPT_DIR / "ai_budget.env"
STATE_DIR = Path("/tmp/polybar-ai-budget")
CACHE_TTL_SECONDS = 300
DEFAULT_CCUSAGE_DIST = Path.home() / "Downloads" / "ccusage-main" / "apps" / "ccusage" / "dist" / "index.js"
CLAUDE_PROJECTS_DIR = Path.home() / ".claude" / "projects"
CODEX_SESSIONS_DIR = Path.home() / ".codex" / "sessions"

PRIMARY = "#00f3ff"
SECONDARY = "#39ff14"
ALERT = "#f7768e"
WARN = "#dfff00"
DISABLED = "#444444"
FOREGROUND = "#a9fef7"

PROVIDERS = {
    "openai": {
        "label": "GPT",
        "weekly_env": "OPENAI_WEEKLY_BUDGET_USD",
        "session_env": "OPENAI_SESSION_BUDGET_USD",
        "session_file": "openai_session.json",
    },
    "anthropic": {
        "label": "CLD",
        "weekly_env": "ANTHROPIC_WEEKLY_BUDGET_USD",
        "session_env": "ANTHROPIC_SESSION_BUDGET_USD",
        "session_file": "anthropic_session.json",
    },
    "gemini": {
        "label": "GEM",
        "weekly_env": "GEMINI_WEEKLY_BUDGET_USD",
        "session_env": "GEMINI_SESSION_BUDGET_USD",
        "session_file": "gemini_session.json",
    },
}


def load_env(path: Path) -> dict:
    data = {}
    if not path.exists():
        return data

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        data[key.strip()] = value.strip().strip("'").strip('"')

    return data


def ensure_state_dir() -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)


def read_json(path: Path):
    if not path.exists():
        return None

    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def write_json(path: Path, payload: dict) -> None:
    ensure_state_dir()
    path.write_text(json.dumps(payload), encoding="utf-8")


def parse_float(value, fallback: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def week_start_ts() -> int:
    local_now = datetime.now().astimezone()
    week_start_local = (local_now - timedelta(days=local_now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    return int(week_start_local.astimezone(timezone.utc).timestamp())


def session_start_ts(provider: str) -> int:
    ensure_state_dir()
    state_path = STATE_DIR / PROVIDERS[provider]["session_file"]
    state = read_json(state_path) or {}
    ts = int(state.get("session_start_ts", 0) or 0)

    if ts <= 0:
        ts = int(time.time())
        write_json(state_path, {"session_start_ts": ts})

    return ts


def reset_session(provider: str) -> None:
    ensure_state_dir()
    state_path = STATE_DIR / PROVIDERS[provider]["session_file"]
    write_json(state_path, {"session_start_ts": int(time.time())})
    refresh(provider)


def refresh(provider: str) -> None:
    cache_path = STATE_DIR / f"{provider}_budget_cache.json"
    if cache_path.exists():
        cache_path.unlink()


def get_cache(provider: str):
    cache_path = STATE_DIR / f"{provider}_budget_cache.json"
    payload = read_json(cache_path)
    if not payload:
        return None

    if time.time() - payload.get("fetched_at", 0) > CACHE_TTL_SECONDS:
        return None

    return payload


def set_cache(provider: str, payload: dict) -> None:
    cache_path = STATE_DIR / f"{provider}_budget_cache.json"
    write_json(cache_path, payload)


def http_get_json(url: str, headers: dict) -> dict:
    request = urllib.request.Request(url, headers=headers, method="GET")
    with urllib.request.urlopen(request, timeout=15) as response:
        return json.loads(response.read().decode("utf-8"))


def sum_money(payload) -> float:
    total = 0.0

    if isinstance(payload, dict):
        for key, value in payload.items():
            if key == "amount":
                if isinstance(value, dict) and "value" in value:
                    total += parse_float(value.get("value"))
                    continue
                if isinstance(value, (int, float, str)):
                    total += parse_float(value)
                    continue
            if key in {"costAmount", "cost_amount"}:
                total += parse_float(value)
                continue
            total += sum_money(value)
    elif isinstance(payload, list):
        for item in payload:
            total += sum_money(item)

    return total


def openai_cost_total(api_key: str, start_ts: int, end_ts: int) -> float:
    base_url = "https://api.openai.com/v1/organization/costs"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    page = None
    total = 0.0

    while True:
        params = {
            "start_time": str(start_ts),
            "end_time": str(end_ts),
            "bucket_width": "1d",
            "limit": "31",
        }
        if page:
            params["page"] = page
        url = f"{base_url}?{urllib.parse.urlencode(params)}"
        payload = http_get_json(url, headers)
        total += sum_money(payload.get("data", payload))

        if not payload.get("has_more") or not payload.get("next_page"):
            break
        page = payload["next_page"]

    return total


def latest_codex_rate_limits() -> dict:
    if not CODEX_SESSIONS_DIR.exists():
        raise FileNotFoundError(str(CODEX_SESSIONS_DIR))

    latest_ts = None
    latest_payload = None

    for path in sorted(CODEX_SESSIONS_DIR.rglob("*.jsonl")):
        try:
            with path.open("r", encoding="utf-8") as handle:
                for raw_line in handle:
                    line = raw_line.strip()
                    if not line:
                        continue

                    try:
                        payload = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    if payload.get("type") != "event_msg":
                        continue

                    body = payload.get("payload")
                    if not isinstance(body, dict) or body.get("type") != "token_count":
                        continue

                    raw_ts = payload.get("timestamp")
                    if not isinstance(raw_ts, str):
                        continue

                    try:
                        ts = datetime.fromisoformat(raw_ts.replace("Z", "+00:00"))
                    except ValueError:
                        continue

                    if latest_ts is None or ts > latest_ts:
                        latest_ts = ts
                        latest_payload = body
        except OSError:
            continue

    if latest_payload is None:
        raise FileNotFoundError("no codex token_count events found")

    return latest_payload


def openai_cost_snapshot(env: dict, session_start: int, week_start: int) -> dict:
    try:
        rate_payload = latest_codex_rate_limits()
        rate_limits = rate_payload.get("rate_limits", {})
        primary = rate_limits.get("primary", {})
        secondary = rate_limits.get("secondary", {})
        return {
            "session_used_pct": parse_float(primary.get("used_percent")),
            "week_used_pct": parse_float(secondary.get("used_percent")),
            "rate_source": "codex",
        }
    except (FileNotFoundError, OSError, json.JSONDecodeError):
        api_key = env.get("OPENAI_ADMIN_KEY", "") or env.get("OPENAI_API_KEY", "")
        if not api_key:
            return {"error": "missing key"}
        return {
            "week_cost": openai_cost_total(api_key, week_start, int(time.time())),
            "session_cost": openai_cost_total(api_key, session_start, int(time.time())),
            "rate_source": "api",
        }


def anthropic_cost_total(api_key: str, start_ts: int, end_ts: int) -> float:
    base_url = "https://api.anthropic.com/v1/organizations/cost_report"
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
        "user-agent": "polybar-ai-budget/1.0",
    }
    page = None
    total = 0.0

    while True:
        params = {
            "starting_at": datetime.fromtimestamp(start_ts, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "ending_at": datetime.fromtimestamp(end_ts, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "bucket_width": "1d",
            "limit": "31",
        }
        if page:
            params["page"] = page
        url = f"{base_url}?{urllib.parse.urlencode(params)}"
        payload = http_get_json(url, headers)
        total += sum_money(payload.get("data", payload))

        if not payload.get("has_more") or not payload.get("next_page"):
            break
        page = payload["next_page"]

    return total / 100.0


def resolve_ccusage_dist(env: dict) -> Path:
    raw_path = env.get("CCUSAGE_DIST_PATH", "").strip()
    candidate = Path(os.path.expanduser(raw_path)) if raw_path else DEFAULT_CCUSAGE_DIST
    return candidate


def run_ccusage_json(env: dict, *args: str):
    ccusage_dist = resolve_ccusage_dist(env)
    if not ccusage_dist.exists():
        raise FileNotFoundError(str(ccusage_dist))

    completed = subprocess.run(
        ["node", str(ccusage_dist), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(completed.stdout)


def format_remaining_duration(target_ts: float) -> str:
    remaining_seconds = max(0, int(target_ts - time.time()))
    remaining_minutes = remaining_seconds // 60
    hours = remaining_minutes // 60
    minutes = remaining_minutes % 60
    return f"{hours}h{minutes:02d}m"


def claude_reset_snapshot(env: dict) -> dict:
    active_blocks_payload = run_ccusage_json(env, "blocks", "--active", "--json", "--offline")
    blocks = active_blocks_payload.get("blocks", [])
    if not isinstance(blocks, list) or not blocks:
        return {"reset_at": None}

    end_time = blocks[0].get("endTime")
    if not isinstance(end_time, str):
        return {"reset_at": None}

    try:
        return {"reset_at": datetime.fromisoformat(end_time.replace("Z", "+00:00")).timestamp()}
    except ValueError:
        return {"reset_at": None}


def yyyymmdd_from_ts(ts: int) -> str:
    return datetime.fromtimestamp(ts).astimezone().strftime("%Y%m%d")


def anthropic_pricing_for_model(model: str) -> dict:
    normalized = (model or "").lower()

    if "opus" in normalized:
        base_input = 15.0 / 1_000_000.0
        output = 75.0 / 1_000_000.0
    elif "haiku-4-5" in normalized or "haiku 4.5" in normalized:
        base_input = 1.0 / 1_000_000.0
        output = 5.0 / 1_000_000.0
    elif "haiku" in normalized:
        base_input = 0.8 / 1_000_000.0
        output = 4.0 / 1_000_000.0
    else:
        base_input = 3.0 / 1_000_000.0
        output = 15.0 / 1_000_000.0

    return {
        "input": base_input,
        "cache_create": base_input * 1.25,
        "cache_read": base_input * 0.10,
        "output": output,
    }


def estimate_anthropic_entry_cost(model: str, usage: dict) -> float:
    pricing = anthropic_pricing_for_model(model)
    return (
        parse_float(usage.get("input_tokens")) * pricing["input"]
        + parse_float(usage.get("cache_creation_input_tokens")) * pricing["cache_create"]
        + parse_float(usage.get("cache_read_input_tokens")) * pricing["cache_read"]
        + parse_float(usage.get("output_tokens")) * pricing["output"]
    )


def scan_claude_costs(start_ts: int) -> float:
    if not CLAUDE_PROJECTS_DIR.exists():
        raise FileNotFoundError(str(CLAUDE_PROJECTS_DIR))

    processed = set()
    total = 0.0

    for path in sorted(CLAUDE_PROJECTS_DIR.rglob("*.jsonl")):
        try:
            with path.open("r", encoding="utf-8") as handle:
                for raw_line in handle:
                    line = raw_line.strip()
                    if not line:
                        continue

                    try:
                        payload = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    if payload.get("type") != "assistant":
                        continue

                    message = payload.get("message")
                    if not isinstance(message, dict):
                        continue

                    usage = message.get("usage")
                    if not isinstance(usage, dict) or usage.get("input_tokens") is None:
                        continue

                    message_id = message.get("id")
                    request_id = payload.get("requestId")
                    if not message_id or not request_id:
                        continue

                    dedupe_key = f"{message_id}:{request_id}"
                    if dedupe_key in processed:
                        continue
                    processed.add(dedupe_key)

                    timestamp = payload.get("timestamp")
                    if not isinstance(timestamp, str):
                        continue

                    try:
                        entry_ts = datetime.fromisoformat(timestamp.replace("Z", "+00:00")).timestamp()
                    except ValueError:
                        continue

                    if entry_ts < start_ts:
                        continue

                    total += estimate_anthropic_entry_cost(message.get("model", ""), usage)
        except OSError:
            continue

    return total


def claude_costs_from_ccusage(env: dict, session_start: int, week_start: int) -> dict:
    session_args = [
        "session",
        "--json",
        "--since",
        yyyymmdd_from_ts(session_start),
    ]
    week_args = [
        "daily",
        "--json",
        "--since",
        yyyymmdd_from_ts(week_start),
    ]

    session_payload = run_ccusage_json(env, *session_args)
    week_payload = run_ccusage_json(env, *week_args)

    session_cost = 0.0
    for item in session_payload.get("sessions", []):
        session_id = item.get("sessionId")
        if not session_id:
            continue
        detail = run_ccusage_json(env, "session", "--json", "--id", session_id)
        for entry in detail.get("entries", []):
            raw_ts = entry.get("timestamp")
            if not isinstance(raw_ts, str):
                continue
            try:
                entry_ts = datetime.fromisoformat(raw_ts.replace("Z", "+00:00")).timestamp()
            except ValueError:
                continue
            if entry_ts >= session_start:
                session_cost += parse_float(entry.get("costUSD"))

    week_cost = parse_float(week_payload.get("totals", {}).get("totalCost"))
    return {"week_cost": week_cost, "session_cost": session_cost, "reset_at": None}


def claude_costs_from_local_logs(session_start: int, week_start: int) -> dict:
    return {
        "week_cost": scan_claude_costs(week_start),
        "session_cost": scan_claude_costs(session_start),
        "reset_at": None,
    }


def anthropic_cost_snapshot(env: dict, session_start: int, week_start: int) -> dict:
    try:
        reset_snapshot = claude_reset_snapshot(env)
        if reset_snapshot.get("reset_at") is not None:
            return reset_snapshot
    except (FileNotFoundError, subprocess.SubprocessError, json.JSONDecodeError, OSError):
        pass

    try:
        ccusage_data = claude_costs_from_ccusage(env, session_start, week_start)
        if ccusage_data["week_cost"] > 0 or ccusage_data["session_cost"] > 0:
            return ccusage_data
    except (FileNotFoundError, subprocess.SubprocessError, json.JSONDecodeError, OSError):
        pass

    return claude_costs_from_local_logs(session_start, week_start)


def gemini_cost_snapshot(status_file: str, session_start: int, week_start: int) -> dict:
    payload = read_json(Path(os.path.expanduser(status_file)))
    if not payload:
        raise FileNotFoundError(status_file)

    entries = payload if isinstance(payload, list) else [payload]
    session_cost = None
    week_cost = None
    budget_amount = None

    for item in entries:
        if not isinstance(item, dict):
            continue
        if budget_amount is None:
            budget_amount = parse_float(item.get("budgetAmount"))

        raw_start = item.get("costIntervalStart") or ""
        try:
            start_ts = int(datetime.fromisoformat(raw_start.replace("Z", "+00:00")).timestamp())
        except ValueError:
            start_ts = 0

        cost_amount = parse_float(item.get("costAmount"))
        if start_ts and start_ts <= week_start:
            week_cost = cost_amount
        if start_ts and start_ts <= session_start:
            session_cost = cost_amount

    latest = entries[-1] if entries else {}
    return {
        "week_cost": week_cost if week_cost is not None else parse_float(latest.get("costAmount")),
        "session_cost": session_cost if session_cost is not None else parse_float(latest.get("costAmount")),
        "budget_amount": budget_amount or 0.0,
    }


def fetch_costs(provider: str, env: dict) -> dict:
    session_start = session_start_ts(provider)
    week_start = week_start_ts()

    if provider == "openai":
        return openai_cost_snapshot(env, session_start, week_start)

    if provider == "anthropic":
        return anthropic_cost_snapshot(env, session_start, week_start)

    status_file = env.get("GEMINI_BUDGET_STATUS_FILE", "")
    if not status_file:
        return {"error": "missing status"}
    return gemini_cost_snapshot(status_file, session_start, week_start)


def fmt_pct(remaining: float, budget: float) -> str:
    if budget <= 0:
        return "0%"
    pct = max(0.0, (remaining / budget) * 100.0)
    if pct >= 100:
        return "100%"
    if pct >= 10:
        return f"{pct:.0f}%"
    return f"{pct:.1f}%"


def fmt_pct_from_used(used_pct: float) -> str:
    remaining_pct = max(0.0, 100.0 - used_pct)
    if remaining_pct >= 100:
        return "100%"
    if remaining_pct >= 10:
        return f"{remaining_pct:.0f}%"
    return f"{remaining_pct:.1f}%"


def render(provider: str, env: dict, data: dict) -> str:
    meta = PROVIDERS[provider]
    label = meta["label"]

    if data.get("error") == "missing key":
        return f"%{{F{DISABLED}}}{label} KEY%{{F-}}"
    if data.get("error") == "missing status":
        return f"%{{F{DISABLED}}}{label} FILE%{{F-}}"
    if data.get("error"):
        return f"%{{F{ALERT}}}{label} ERR%{{F-}}"

    weekly_budget = parse_float(env.get(meta["weekly_env"]))
    session_budget = parse_float(env.get(meta["session_env"]))
    if provider == "gemini" and weekly_budget <= 0:
        weekly_budget = parse_float(data.get("budget_amount"))
    if provider == "gemini" and session_budget <= 0 and weekly_budget > 0:
        session_budget = weekly_budget

    if weekly_budget <= 0 or session_budget <= 0:
        return f"%{{F{DISABLED}}}{label} CFG%{{F-}}"

    if provider == "anthropic" and data.get("reset_at") is not None:
        return f"%{{F{PRIMARY}}}{label}%{{F-}} %{{F{FOREGROUND}}}{format_remaining_duration(parse_float(data.get('reset_at')))}%{{F-}}"

    if provider == "openai" and data.get("session_used_pct") is not None and data.get("week_used_pct") is not None:
        return f"%{{F{PRIMARY}}}{label}%{{F-}}"

    remaining_week = weekly_budget - parse_float(data.get("week_cost"))
    remaining_session = session_budget - parse_float(data.get("session_cost"))

    if remaining_week < 0 or remaining_session < 0:
        state_color = ALERT
    elif remaining_week < 5 or remaining_session < 2:
        state_color = WARN
    else:
        state_color = SECONDARY

    return (
        f"%{{F{PRIMARY}}}{label}%{{F-}} "
        f"%{{F{FOREGROUND}}}S{fmt_pct(remaining_session, session_budget)}%{{F-}}/"
        f"%{{F{state_color}}}W{fmt_pct(remaining_week, weekly_budget)}%{{F-}}"
    )


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in PROVIDERS:
        print("usage: ai_budget.py <openai|anthropic|gemini> [reset-session|refresh]")
        return 1

    provider = sys.argv[1]
    action = sys.argv[2] if len(sys.argv) > 2 else "print"

    if action == "reset-session":
        reset_session(provider)
        return 0
    if action == "refresh":
        refresh(provider)
        return 0

    env = load_env(CONFIG_PATH)
    cached = get_cache(provider)
    if cached:
        print(render(provider, env, cached))
        return 0

    try:
        data = fetch_costs(provider, env)
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        data = {"error": "fetch"}

    payload = {"fetched_at": time.time(), **data}
    set_cache(provider, payload)
    print(render(provider, env, payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

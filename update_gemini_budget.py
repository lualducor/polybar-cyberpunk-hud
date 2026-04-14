#!/usr/bin/env python3
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


JSON_PATH = Path.home() / ".config" / "polybar" / "gemini_budget.json"


def usage() -> int:
    print("usage: update_gemini_budget.py <cost_amount> [budget_amount] [cost_interval_start_utc]")
    return 1


def parse_float(value: str) -> float:
    try:
        return float(value)
    except ValueError as exc:
        raise SystemExit(f"invalid number: {value}") from exc


def normalize_ts(value: str) -> str:
    if not value:
        now = datetime.now(timezone.utc)
        week_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_start = week_start.replace(day=week_start.day - now.weekday())
        return week_start.isoformat().replace("+00:00", "Z")

    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
    except ValueError as exc:
        raise SystemExit("invalid timestamp, use ISO 8601 like 2026-04-07T00:00:00Z") from exc


def main() -> int:
    if len(sys.argv) < 2:
        return usage()

    cost_amount = parse_float(sys.argv[1])
    budget_amount = parse_float(sys.argv[2]) if len(sys.argv) >= 3 else None
    cost_interval_start = normalize_ts(sys.argv[3] if len(sys.argv) >= 4 else "")

    if JSON_PATH.exists():
        try:
            payload = json.loads(JSON_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            payload = {}
    else:
        payload = {}

    if budget_amount is None:
        budget_amount = float(payload.get("budgetAmount", 25.0))

    payload.update(
        {
            "budgetDisplayName": payload.get("budgetDisplayName", "Gemini Weekly"),
            "costAmount": cost_amount,
            "costIntervalStart": cost_interval_start,
            "budgetAmount": budget_amount,
            "budgetAmountType": payload.get("budgetAmountType", "SPECIFIED_AMOUNT"),
            "currencyCode": payload.get("currencyCode", "USD"),
        }
    )

    JSON_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"updated {JSON_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

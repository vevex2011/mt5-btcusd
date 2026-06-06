#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


BUY_ROLES = ("BUY_PULLBACK", "BUY_BREAKOUT")
SELL_ROLES = ("SELL_PULLBACK", "SELL_BREAKDOWN")


def default_mt5_files_dir() -> Path:
    return (
        Path.home()
        / "Library/Application Support/net.metaquotes.wine.metatrader5"
        / "drive_c/Program Files/MetaTrader 5/MQL5/Files"
    )


def parse_args() -> argparse.Namespace:
    files_dir = default_mt5_files_dir()
    parser = argparse.ArgumentParser(
        description="Generate deterministic BTCUSD chart-line suggestions for the MT5 pending EA."
    )
    parser.add_argument(
        "--context",
        type=Path,
        default=files_dir / "codex_btcusd_market_context.json",
        help="Market context JSON exported by the EA.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=files_dir / "codex_ai_lines_btcusd.json",
        help="Suggestion JSON consumed by the EA.",
    )
    parser.add_argument("--ttl-seconds", type=int, default=900)
    parser.add_argument("--interval-seconds", type=int, default=900)
    parser.add_argument("--pullback-offset-atr", type=float, default=0.10)
    parser.add_argument("--breakout-offset-atr", type=float, default=0.05)
    parser.add_argument("--retest-offset-atr", type=float, default=0.35)
    parser.add_argument(
        "--include-retest",
        action="store_true",
        help="Also emit trigger+retest-entry line pairs.",
    )
    parser.add_argument("--loop", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def load_context(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"context file not found: {path}")
    payload = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(payload, dict):
        raise ValueError("context JSON must be an object")
    return payload


def number(value: Any) -> float | None:
    if isinstance(value, (int, float)) and math.isfinite(float(value)):
        return float(value)
    if isinstance(value, str):
        try:
            parsed = float(value)
        except ValueError:
            return None
        if math.isfinite(parsed):
            return parsed
    return None


def normalize_price(context: dict[str, Any], value: float) -> float:
    digits = 2
    for candidate in (
        context.get("digits"),
        context.get("price_digits"),
        context.get("symbol_digits"),
    ):
        parsed = number(candidate)
        if parsed is not None:
            digits = max(0, int(parsed))
            break
    return round(value, digits)


def h4_trend_side(context: dict[str, Any]) -> str | None:
    trend = context.get("h4_trend")
    if isinstance(trend, dict) and trend.get("available") is False:
        return None

    direction = str(context.get("h4_ema200_direction") or "").upper()
    if not direction and isinstance(trend, dict):
        direction = str(trend.get("ema200_direction") or "").upper()

    if direction in {"UP", "RISING", "BULLISH", "BUY"}:
        return "BUY"
    if direction in {"DOWN", "FALLING", "BEARISH", "SELL"}:
        return "SELL"
    return None


def context_numbers(context: dict[str, Any]) -> tuple[float, float, float, float, float]:
    breakout_range = context.get("breakout_range") or {}
    if not isinstance(breakout_range, dict):
        breakout_range = {}

    fast = number(context.get("d1_ema_fast"))
    slow = number(context.get("d1_ema_slow"))
    atr = number(context.get("d1_atr"))
    high = number(breakout_range.get("high"))
    low = number(breakout_range.get("low"))
    if fast is None or slow is None or atr is None or high is None or low is None:
        raise ValueError("context is missing d1_ema_fast/d1_ema_slow/d1_atr/breakout_range")
    if atr <= 0.0 or high <= low:
        raise ValueError("context has invalid ATR or breakout range")
    return fast, slow, atr, high, low


def build_rule_lines(context: dict[str, Any], args: argparse.Namespace) -> tuple[dict[str, float], str]:
    side = h4_trend_side(context)
    fast, slow, atr, high, low = context_numbers(context)
    lines: dict[str, float] = {}

    if side in {None, "BUY"}:
        lines["BUY_PULLBACK"] = normalize_price(
            context,
            min(fast, slow) - atr * args.pullback_offset_atr,
        )
        lines["BUY_BREAKOUT"] = normalize_price(
            context,
            high + atr * args.breakout_offset_atr,
        )
        if args.include_retest:
            trigger = lines["BUY_BREAKOUT"]
            lines["BUY_BREAKOUT_TRIGGER"] = trigger
            lines["BUY_RETEST_ENTRY"] = normalize_price(
                context,
                trigger - atr * args.retest_offset_atr,
            )

    if side == "BUY":
        return lines, "H4_EMA200_UP"

    if side in {None, "SELL"}:
        lines["SELL_PULLBACK"] = normalize_price(
            context,
            max(fast, slow) + atr * args.pullback_offset_atr,
        )
        lines["SELL_BREAKDOWN"] = normalize_price(
            context,
            low - atr * args.breakout_offset_atr,
        )
        if args.include_retest:
            trigger = lines["SELL_BREAKDOWN"]
            lines["SELL_BREAKDOWN_TRIGGER"] = trigger
            lines["SELL_RETEST_ENTRY"] = normalize_price(
                context,
                trigger + atr * args.retest_offset_atr,
            )

    if side is None:
        return lines, "H4_EMA200_FLAT_RANGE_BOTH_SIDES"

    return lines, "H4_EMA200_DOWN"


def build_output(
    context: dict[str, Any],
    lines: dict[str, float],
    reason: str,
    ttl_seconds: int,
) -> dict[str, Any]:
    now = int(context.get("server_time") or time.time())
    return {
        "symbol": str(context.get("symbol", "BTCUSD")),
        "generated_at": now,
        "expires_at": now + ttl_seconds,
        "source": "rule_line_advisor_btcusd.py",
        "advisor_mode": "rule",
        "reason": reason,
        "context_server_time": context.get("server_time"),
        "context_server_time_text": context.get("server_time_text"),
        "lines": lines,
    }


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(
        json.dumps(payload, separators=(",", ":"), sort_keys=True) + "\n",
        encoding="utf-8",
    )
    tmp.replace(path)


def log(message: str, level: str = "INFO") -> None:
    timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
    print(f"{timestamp} {level} {message}", flush=True)


def run_once(args: argparse.Namespace) -> bool:
    context = load_context(args.context)
    lines, reason = build_rule_lines(context, args)
    output = build_output(context, lines, reason, args.ttl_seconds)
    if args.dry_run:
        print(json.dumps(output, indent=2, sort_keys=True))
    else:
        atomic_write_json(args.output, output)
        log(f"wrote {len(lines)} rule line(s) to {args.output}: {reason}")
    return bool(lines)


def main() -> int:
    args = parse_args()
    if args.ttl_seconds < 1 or args.interval_seconds < 1:
        raise SystemExit("ttl and interval must be positive.")
    if args.pullback_offset_atr < 0.0 or args.breakout_offset_atr < 0.0:
        raise SystemExit("ATR offsets must be non-negative.")

    if not args.loop:
        run_once(args)
        return 0

    while True:
        try:
            run_once(args)
        except KeyboardInterrupt:
            return 0
        except Exception as exc:
            log(f"rule advisor error: {exc}", level="ERROR")
        time.sleep(args.interval_seconds)


if __name__ == "__main__":
    raise SystemExit(main())

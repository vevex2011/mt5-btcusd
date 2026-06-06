#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


ROLES = (
    "BUY_PULLBACK",
    "BUY_BREAKOUT",
    "BUY_BREAKOUT_TRIGGER",
    "BUY_RETEST_ENTRY",
    "SELL_PULLBACK",
    "SELL_BREAKDOWN",
    "SELL_BREAKDOWN_TRIGGER",
    "SELL_RETEST_ENTRY",
)
BUY_ROLES = {
    "BUY_PULLBACK",
    "BUY_BREAKOUT",
    "BUY_BREAKOUT_TRIGGER",
    "BUY_RETEST_ENTRY",
}
SELL_ROLES = {
    "SELL_PULLBACK",
    "SELL_BREAKDOWN",
    "SELL_BREAKDOWN_TRIGGER",
    "SELL_RETEST_ENTRY",
}

def default_mt5_files_dir() -> Path:
    return (
        Path.home()
        / "Library/Application Support/net.metaquotes.wine.metatrader5"
        / "drive_c/Program Files/MetaTrader 5/MQL5/Files"
    )


def default_project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_sub2api_config_path() -> Path:
    return Path(
        os.getenv("SUB2API_CONFIG_FILE", default_project_root() / "sub2api.conf")
    ).expanduser()


def getenv_first(*names: str, default: str = "") -> str:
    for name in names:
        value = os.getenv(name)
        if value:
            return value
    return default


def strip_matching_quotes(value: str) -> str:
    value = value.strip().rstrip(",").strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def config_key_name(key: str) -> str:
    return strip_matching_quotes(key).strip().lower().replace("-", "_")


def parse_sub2api_config_line(line: str) -> tuple[str, str] | None:
    line = line.strip()
    if not line or line.startswith("#") or line.startswith("//"):
        return None
    if line in {"{", "}"}:
        return None

    if "=" in line:
        key, value = line.split("=", 1)
    elif ":" in line:
        key, value = line.split(":", 1)
    else:
        return None

    key = config_key_name(key)
    value = strip_matching_quotes(value)
    if not key or value == "":
        return None
    return key, value


def load_sub2api_config(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}

    text = path.read_text(encoding="utf-8-sig")
    stripped = text.strip()
    raw_values: dict[str, Any]
    if stripped.startswith("{"):
        parsed = json.loads(stripped)
        if not isinstance(parsed, dict):
            return {}
        raw_values = parsed
    else:
        raw_values = {}
        for line in text.splitlines():
            parsed_line = parse_sub2api_config_line(line)
            if parsed_line is None:
                continue
            key, value = parsed_line
            raw_values[key] = value

    aliases = {
        "base_url": {
            "base_url",
            "baseurl",
            "url",
            "sub2api_base_url",
            "default_sub2api_base_url",
        },
        "api_key": {
            "api_key",
            "apikey",
            "key",
            "token",
            "sub2api_api_key",
            "default_sub2api_api_key",
        },
        "model": {
            "model",
            "sub2api_model",
            "default_sub2api_model",
        },
        "reasoning_effort": {
            "reasoning_effort",
            "reasoningeffort",
            "sub2api_reasoning_effort",
            "default_sub2api_reasoning_effort",
        },
    }
    config: dict[str, str] = {}
    for raw_key, raw_value in raw_values.items():
        key = config_key_name(str(raw_key))
        value = strip_matching_quotes(str(raw_value))
        for canonical_key, names in aliases.items():
            if key in names and value:
                config[canonical_key] = value
                break
    return config


def parse_args() -> argparse.Namespace:
    files_dir = default_mt5_files_dir()
    pre_parser = argparse.ArgumentParser(add_help=False)
    pre_parser.add_argument(
        "--config",
        type=Path,
        default=default_sub2api_config_path(),
        help="sub2api config file. Defaults to the mt5 workspace sub2api.conf.",
    )
    pre_args, _ = pre_parser.parse_known_args()
    config_path = pre_args.config.expanduser()
    config = load_sub2api_config(config_path)

    parser = argparse.ArgumentParser(
        description="Generate BTCUSD AI chart-line suggestions for the MT5 EA.",
        parents=[pre_parser],
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
    parser.add_argument(
        "--screenshot",
        type=Path,
        default=files_dir / "codex_btcusd_h4.png",
        help="Optional BTCUSD H4 screenshot exported by the EA.",
    )
    parser.add_argument(
        "--base-url",
        default=getenv_first(
            "SUB2API_BASE_URL",
            "AI_LINE_ADVISOR_BASE_URL",
            "OPENAI_BASE_URL",
            default=config.get("base_url", ""),
        ),
        help="OpenAI-compatible API base URL, usually ending in /v1.",
    )
    parser.add_argument(
        "--api-key",
        default=getenv_first(
            "SUB2API_API_KEY",
            "AI_LINE_ADVISOR_API_KEY",
            "OPENAI_API_KEY",
            default=config.get("api_key", ""),
        ),
        help="API key for the OpenAI-compatible endpoint.",
    )
    parser.add_argument(
        "--model",
        default=getenv_first(
            "SUB2API_MODEL",
            "AI_LINE_ADVISOR_MODEL",
            "OPENAI_MODEL",
            default=config.get("model", ""),
        ),
        help="Model name to send to the endpoint.",
    )
    parser.add_argument("--ttl-seconds", type=int, default=900)
    parser.add_argument("--interval-seconds", type=int, default=300)
    parser.add_argument("--timeout-seconds", type=int, default=60)
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument(
        "--reasoning-effort",
        default=getenv_first(
            "SUB2API_REASONING_EFFORT",
            "AI_LINE_ADVISOR_REASONING_EFFORT",
            "OPENAI_REASONING_EFFORT",
            default=config.get("reasoning_effort", ""),
        ),
    )
    parser.add_argument("--loop", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--no-screenshot", action="store_true")
    parser.add_argument(
        "--no-response-format",
        action="store_true",
        help="Disable response_format for endpoints that do not support it.",
    )
    return parser.parse_args()


def require_api_config(args: argparse.Namespace) -> None:
    missing = []
    if not args.base_url:
        missing.append("SUB2API_BASE_URL")
    if not args.api_key:
        missing.append("SUB2API_API_KEY")
    if not args.model:
        missing.append("SUB2API_MODEL")
    if missing:
        raise SystemExit(
            "Missing API config: "
            + ", ".join(missing)
            + f". Fill {args.config}, set env vars, or pass --base-url/--api-key/--model."
        )


def load_context(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"context file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8-sig"))


def build_messages(context: dict[str, Any], screenshot_path: Path | None) -> list[dict[str, Any]]:
    system = (
        "You are generating experimental BTCUSD chart-line levels for a demo MT5 EA. "
        "Return strict JSON only. Do not include explanations, markdown, comments, or "
        "non-JSON text. The EA has its own spread, calendar, sizing, and price-validity "
        "checks. Calendar/news events are not a no-trade filter in this experiment. "
        "You only choose line prices."
    )
    user = {
        "task": "Choose zero or more BTCUSD chart-line prices for the next EA check.",
        "trading_cycle": "The live execution/trading cycle is 30 minutes (M30). Use the D1 chart-line context as higher-level levels, but make suggestions suitable for M30 pending-order testing.",
        "image_context": "A BTCUSD H4 screenshot may be attached. Use it to understand recent structure, trend, volatility, and obvious support/resistance, but return only numeric line prices.",
        "direction_policy": "When market_context.h4_ema200_direction is clearly UP, prefer BUY_* lines. When it is clearly DOWN, prefer SELL_* lines. When it is NONE, FLAT, UNKNOWN, or missing, you may return both BUY_* and SELL_* levels if the chart has clean range support/resistance or breakout boundaries; otherwise return no lines.",
        "allowed_line_keys": list(ROLES),
        "rules": [
            "Return a JSON object with a 'lines' object.",
            "Use numeric prices only.",
            "Omit a line if the setup is unclear.",
            "Do not short a clearly rising H4 EMA200 and do not buy a clearly falling H4 EMA200.",
            "If H4 EMA200 direction is flat or unclear, range-style two-sided lines are allowed, but only at obvious support/resistance or breakout boundaries.",
            "If H4 trend context conflicts with the screenshot, prefer no lines.",
            "You may mix BUY_* and SELL_* keys only when the H4 EMA200 direction is flat or unclear.",
            "Do not create dense bracket/grid behavior; use at most one clear BUY zone and one clear SELL zone.",
            "Respect market_context.signal_timeframe and market_context.trade_cycle_minutes when deciding whether a level is actionable soon.",
            "When H4 EMA200 is UP and a long setup is valid, prioritize BUY_PULLBACK and BUY_BREAKOUT as the core lines before considering retest lines.",
            "When H4 EMA200 is DOWN and a short setup is valid, prioritize SELL_PULLBACK and SELL_BREAKDOWN as the core lines before considering retest lines.",
            "Do not omit an obvious breakout/breakdown level merely because a pullback line also exists.",
            "BUY_BREAKOUT_TRIGGER and BUY_RETEST_ENTRY must appear together when using a buy retest setup; otherwise omit both.",
            "SELL_BREAKDOWN_TRIGGER and SELL_RETEST_ENTRY must appear together when using a sell retest setup; otherwise omit both.",
            "Prefer a small number of high-conviction lines over filling every line.",
            "You may use the EA reference lines as anchors but can adjust them.",
        ],
        "response_schema": {
            "lines": {
                "BUY_PULLBACK": "number optional",
                "BUY_BREAKOUT": "number optional",
                "BUY_BREAKOUT_TRIGGER": "number optional",
                "BUY_RETEST_ENTRY": "number optional",
                "SELL_PULLBACK": "number optional",
                "SELL_BREAKDOWN": "number optional",
                "SELL_BREAKDOWN_TRIGGER": "number optional",
                "SELL_RETEST_ENTRY": "number optional",
            }
        },
        "market_context": context,
    }
    user_text = json.dumps(user, ensure_ascii=False, separators=(",", ":"))
    user_content: Any = user_text
    if screenshot_path is not None and screenshot_path.exists():
        user_content = [
            {"type": "text", "text": user_text},
            {
                "type": "image_url",
                "image_url": {
                    "url": image_data_url(screenshot_path),
                    "detail": "high",
                },
            },
        ]
    elif screenshot_path is not None:
        print(f"screenshot not found, sending text-only context: {screenshot_path}", file=sys.stderr)

    return [
        {"role": "system", "content": system},
        {"role": "user", "content": user_content},
    ]


def image_data_url(path: Path) -> str:
    data = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:image/png;base64,{data}"


def call_chat_completions(args: argparse.Namespace, messages: list[dict[str, Any]]) -> str:
    url = args.base_url.rstrip("/") + "/chat/completions"
    payload: dict[str, Any] = {
        "model": args.model,
        "messages": messages,
        "temperature": args.temperature,
        "reasoning_effort": args.reasoning_effort,
    }
    if not args.no_response_format:
        payload["response_format"] = {"type": "json_object"}

    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {args.api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=args.timeout_seconds) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"API HTTP {exc.code}: {detail}") from exc

    parsed = json.loads(body)
    return parsed["choices"][0]["message"]["content"]


def extract_json_object(text: str) -> dict[str, Any]:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if not match:
            raise
        return json.loads(match.group(0))


def coerce_price(value: Any) -> float | None:
    if isinstance(value, dict):
        value = value.get("price")
    if isinstance(value, (int, float)):
        price = float(value)
    elif isinstance(value, str):
        try:
            price = float(value.strip())
        except ValueError:
            return None
    else:
        return None
    if price <= 0:
        return None
    return price


def normalize_lines(raw: dict[str, Any], context: dict[str, Any] | None = None) -> dict[str, float]:
    source = raw.get("lines", raw)
    if not isinstance(source, dict):
        raise ValueError("AI response must contain an object named 'lines'.")

    lines: dict[str, float] = {}
    for role in ROLES:
        price = None
        for key in (role, f"BTC_{role}"):
            if key in source:
                price = coerce_price(source[key])
                break
        if price is not None:
            lines[role] = price
    lines = enforce_single_direction(lines)
    return enforce_context_trend(lines, context)


def enforce_single_direction(lines: dict[str, float]) -> dict[str, float]:
    has_buy = any(role in BUY_ROLES for role in lines)
    has_sell = any(role in SELL_ROLES for role in lines)
    if has_buy and has_sell:
        buy_count = sum(1 for role in lines if role in BUY_ROLES)
        sell_count = sum(1 for role in lines if role in SELL_ROLES)
        if buy_count == sell_count:
            return {}
        keep_roles = BUY_ROLES if buy_count > sell_count else SELL_ROLES
        lines = {role: price for role, price in lines.items() if role in keep_roles}

    if ("BUY_BREAKOUT_TRIGGER" in lines) != ("BUY_RETEST_ENTRY" in lines):
        lines.pop("BUY_BREAKOUT_TRIGGER", None)
        lines.pop("BUY_RETEST_ENTRY", None)
    if ("SELL_BREAKDOWN_TRIGGER" in lines) != ("SELL_RETEST_ENTRY" in lines):
        lines.pop("SELL_BREAKDOWN_TRIGGER", None)
        lines.pop("SELL_RETEST_ENTRY", None)
    return lines


def enforce_context_trend(
    lines: dict[str, float], context: dict[str, Any] | None
) -> dict[str, float]:
    side = infer_context_trend_side(context)
    if side == "BUY":
        return {role: price for role, price in lines.items() if role in BUY_ROLES}
    if side == "SELL":
        return {role: price for role, price in lines.items() if role in SELL_ROLES}
    return {}


def infer_context_trend_side(context: dict[str, Any] | None) -> str | None:
    if not isinstance(context, dict):
        return None

    h4_trend = context.get("h4_trend")
    if isinstance(h4_trend, dict) and h4_trend.get("available") is False:
        return None

    direction = str(context.get("h4_ema200_direction") or "").upper()
    if not direction and isinstance(h4_trend, dict):
        direction = str(h4_trend.get("ema200_direction") or "").upper()

    if direction in {"UP", "RISING", "BULLISH", "BUY"}:
        return "BUY"
    if direction in {"DOWN", "FALLING", "BEARISH", "SELL"}:
        return "SELL"
    return None


def build_output(context: dict[str, Any], lines: dict[str, float], ttl_seconds: int) -> dict[str, Any]:
    now = int(context.get("server_time") or time.time())
    return {
        "symbol": str(context.get("symbol", "BTCUSD")),
        "generated_at": now,
        "expires_at": now + ttl_seconds,
        "source": "ai_line_advisor_btcusd.py",
        "context_server_time": context.get("server_time"),
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


def run_once(args: argparse.Namespace) -> bool:
    context = load_context(args.context)
    screenshot_path = None if args.no_screenshot else args.screenshot
    messages = build_messages(context, screenshot_path)
    response_text = call_chat_completions(args, messages)
    response_json = extract_json_object(response_text)
    lines = normalize_lines(response_json, context)
    output = build_output(context, lines, args.ttl_seconds)
    if not lines:
        if args.dry_run:
            print(json.dumps(output, indent=2, sort_keys=True))
        else:
            atomic_write_json(args.output, output)
            print(f"wrote 0 AI lines to {args.output} (clear signal)")
        return False

    if args.dry_run:
        print(json.dumps(output, indent=2, sort_keys=True))
    else:
        atomic_write_json(args.output, output)
        print(f"wrote {len(lines)} AI line(s) to {args.output}")
    return True


def main() -> int:
    args = parse_args()
    require_api_config(args)
    if args.ttl_seconds < 1 or args.interval_seconds < 1 or args.timeout_seconds < 1:
        raise SystemExit("ttl, interval, and timeout must be positive.")

    if not args.loop:
        run_once(args)
        return 0

    while True:
        try:
            run_once(args)
        except KeyboardInterrupt:
            return 0
        except Exception as exc:
            print(f"advisor error: {exc}", file=sys.stderr)
        time.sleep(args.interval_seconds)


if __name__ == "__main__":
    raise SystemExit(main())

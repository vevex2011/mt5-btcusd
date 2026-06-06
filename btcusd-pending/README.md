# BTCUSD Pending Order EA

`CodexPendingOrderEA_BTCUSD` is an experimental BTCUSD-only EA for testing
three pending-order ideas in one isolated strategy:

- `LIMIT_REVERSION`: trade the trend pullback with Buy Limit or Sell Limit.
- `STOP_BREAKOUT`: trade continuation with a breakout/breakdown pending order.
- `STOP_LIMIT_RETEST`: trigger on breakout/breakdown, then enter on retest.

The EA defaults to `InpDryRun=false`, so valid plans are submitted as managed
pending orders. Set `InpDryRun=true` when you only want logs for the exact
pending orders it would submit, including type, magic number, volume, entry,
stop loss, take profit, expiration, and fallback sizing.

It also supports chart-line trading through the shared indicators in the sibling
`chart-line-indicators` worktree. With `InpUseCommonChartLineIndicators=true`,
the EA does not create entry lines by default. The common indicators first draw
inactive lines such as `BTC_BUY_PULLBACK_INIT`; those are ignored by the EA.
After you manually drag an `_INIT` line once, the indicator creates the armed
line name, and the EA can turn that line into a managed pending order.

The armed chart-line names are:

- `BTC_BUY_PULLBACK`
- `BTC_SELL_PULLBACK`
- `BTC_BUY_BREAKOUT`
- `BTC_SELL_BREAKDOWN`
- `BTC_BUY_BREAKOUT_TRIGGER` plus `BTC_BUY_RETEST_ENTRY`
- `BTC_SELL_BREAKDOWN_TRIGGER` plus `BTC_SELL_RETEST_ENTRY`

The EA leaves chart-line labels to the common indicators by default
(`InpShowChartLineLabels=false`). Legacy EA auto-created lines are still
available by setting `InpUseCommonChartLineIndicators=false` and
`InpAutoCreateChartLines=true`, but the safer default is the drag-to-arm
indicator flow.

For fully automated demo testing, `InpEnableAIChartLineSuggestions=true` lets
the EA read line suggestions from `codex_ai_lines_btcusd.json` in the MT5
`MQL5/Files` sandbox. The file name is historical: suggestions can come from the
deterministic rule advisor or from ChatGPT/sub2api. Those suggestions create or
move the armed chart-line objects directly, so no manual drag is required. When
suggestions are enabled, the built-in non-chart-line modes are paused by default
with `InpPauseAutoModesWhenAIChartLineSuggestionsEnabled=true`, so results are
easier to attribute to the suggestion file.

The EA also exports `codex_btcusd_market_context.json` and a BTCUSD H4
screenshot named `codex_btcusd_h4.png` to the same `MQL5/Files` sandbox.
`scripts/rule_line_advisor_btcusd.py` reads that context and writes the
suggestion file without calling any AI API. `scripts/ai_line_advisor_btcusd.py`
is kept as a temporary/manual AI comparison path.

Expected JSON shape:

```json
{
  "symbol": "BTCUSD",
  "generated_at": 1778716800,
  "expires_at": 1778717700,
  "lines": {
    "BUY_PULLBACK": 102350.0,
    "BUY_BREAKOUT": 105200.0,
    "BUY_BREAKOUT_TRIGGER": 105200.0,
    "BUY_RETEST_ENTRY": 104400.0,
    "SELL_PULLBACK": 107200.0,
    "SELL_BREAKDOWN": 98500.0,
    "SELL_BREAKDOWN_TRIGGER": 98500.0,
    "SELL_RETEST_ENTRY": 99200.0
  }
}
```

Full object names such as `BTC_BUY_PULLBACK` are also accepted. The timestamp is
required by default so stale AI suggestions do not keep trading.

Run the rule advisor once:

```bash
./scripts/rule_line_advisor_btcusd.py
```

Run it continuously:

```bash
./scripts/rule_line_advisor_btcusd.py --loop --interval-seconds 900 --ttl-seconds 900
```

The macOS watchdog starts this rule loop automatically by default, using a 15
minute cycle. The EA also writes signal/deal TSV files under
`MQL5/Files/codex-mt5-btcusd-pending`, and the edge dashboard importer can load
those rows into PostgreSQL together with the latest line suggestion JSON.

Run the AI advisor manually:

```bash
./scripts/ai_line_advisor_btcusd.py
```

The advisor reads its API settings from the mt5 workspace config file by
default:

```text
/Users/xww/Documents/mt5/sub2api.conf
```

Supported keys include `SUB2API_BASE_URL`, `SUB2API_API_KEY`,
`SUB2API_MODEL`, and `SUB2API_REASONING_EFFORT`. Command-line flags and
environment variables can still override the config when needed.

The script defaults to:

- input: `MQL5/Files/codex_btcusd_market_context.json`
- screenshot: `MQL5/Files/codex_btcusd_h4.png`
- output: `MQL5/Files/codex_ai_lines_btcusd.json`
- TTL: `900` seconds

Use `--dry-run` to print either advisor output without writing the EA file.

When chart-line objects are present, `InpPauseAutoModesWhenChartLinesExist=true`
pauses the automatic three-mode strategy by default, so the chart lines become
the execution plan. Line trading still uses the same spread, calendar, sizing,
SL, TP, duplicate-order, and transaction logging controls.

With live trading enabled, dragging a line updates the matching pending order
for that order type instead of adding another order. If the desired volume has
changed, MT5 keeps the existing pending-order volume; cancel it manually if you
want the EA to recreate it with the newly calculated volume.

## Runtime Defaults

- Symbol: `BTCUSD`
- Signal timeframe: `M30`
- Trading cycle: `30` minutes
- Trend filter timeframe: `H4`
- Chart-line timeframe: `D1`
- Dry run: `false`
- Common chart-line indicators: `true`
- AI chart-line suggestions: `true`
- AI suggestion file: `codex_ai_lines_btcusd.json`
- AI market context export: `codex_btcusd_market_context.json`
- AI H4 screenshot export: `codex_btcusd_h4.png`
- Pause auto modes when AI suggestions are enabled: `true`
- Fast EMA: `20`
- Slow EMA: `50`
- Trend baseline EMA: `200`
- ATR period: `14`
- Auto-create chart lines: `false`
- Skip chart-line orders on fresh auto-create: `true`
- Select auto-created chart lines: `true`
- Auto-create both directions: `false`
- Auto-remove inactive direction: `false`
- Auto-update chart lines: `false`
- Show chart-line labels: `false`
- H4 EMA200 slope no longer blocks AI/manual chart-line trading; it remains exported
  in context for observation only.
- Limit magic: `2026050711`
- Stop magic: `2026050712`
- Stop-limit magic: `2026050713`
- Chart-line magic: `2026050714`

The strategy reads the shared `CodexCalendarCache.USD.*` global variables
written by `CodexCalendarCacheService`, so high-risk calendar blocks are
respected when that service is running.

## Install

```bash
./scripts/install_mt5_ea.sh
```

The script installs the EA into MT5 under `Experts/CodexAutotrade` and installs
the shared calendar service from the sibling `services` directory. If the
sibling `chart-line-indicators` worktree is present, the script also installs
and compiles the common drag-to-arm indicators under
`Indicators/CodexAutotrade/ChartLines`.

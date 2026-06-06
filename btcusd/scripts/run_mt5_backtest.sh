#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MT5_APP="${MT5_APP:-$HOME/Applications/MetaTrader 5.app}"
WINEPREFIX_DIR="${MT5_WINEPREFIX:-$HOME/Library/Application Support/net.metaquotes.wine.metatrader5}"
WINE_BIN="$MT5_APP/Contents/SharedSupport/wine/bin/wine64"
TERMINAL_EXE='C:\Program Files\MetaTrader 5\terminal64.exe'
CONFIG_DIR="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/config"
CONFIG_FILE="$CONFIG_DIR/codex-trendpullback-btcusd-lastmonth.ini"
ROOT_CONFIG_FILE="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/codex-trendpullback-btcusd-lastmonth.ini"

FROM_DATE="${1:-2026.02.19}"
TO_DATE="${2:-2026.03.19}"
SYMBOL="${3:-BTCUSD}"
PERIOD="${4:-M30}"
DEPOSIT="${5:-10000}"
SYMBOL_LOWER="$(printf '%s' "$SYMBOL" | tr '[:upper:]' '[:lower:]')"
FROM_STAMP="${FROM_DATE//./}"
TO_STAMP="${TO_DATE//./}"

mkdir -p "$CONFIG_DIR"
mkdir -p "$(dirname "$ROOT_CONFIG_FILE")"

cat >"$ROOT_CONFIG_FILE" <<EOF
[Tester]
Expert=CodexAutotrade\\CodexTrendPullbackEA_BTCUSD.ex5
Symbol=$SYMBOL
Period=$PERIOD
Optimization=0
Model=0
FromDate=$FROM_DATE
ToDate=$TO_DATE
ForwardMode=0
Deposit=$DEPOSIT
Currency=USD
Leverage=100
ExecutionMode=0
OptimizationCriterion=6
Visual=0
ReplaceReport=1
ShutdownTerminal=1
Report=Reports\\codex-trendpullback-btcusd-${SYMBOL_LOWER}-${FROM_STAMP}-${TO_STAMP}
EOF

cp "$ROOT_CONFIG_FILE" "$CONFIG_FILE"

CONFIG_WIN='C:\codex-trendpullback-btcusd-lastmonth.ini'

WINEPREFIX="$WINEPREFIX_DIR" "$WINE_BIN" "$TERMINAL_EXE" /portable "/config:$CONFIG_WIN"

echo "config: $ROOT_CONFIG_FILE"

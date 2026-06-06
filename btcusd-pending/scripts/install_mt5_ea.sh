#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EA_NAME="CodexPendingOrderEA_BTCUSD"
SOURCE_FILE="$ROOT_DIR/ea/$EA_NAME.mq5"
TARGET_DIR="${MT5_EXPERTS_DIR:-$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/CodexAutotrade}"
TARGET_FILE="$TARGET_DIR/$EA_NAME.mq5"

mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE"
cp "$ROOT_DIR/ea/CodexModelRecommendations.mqh" "$TARGET_DIR/CodexModelRecommendations.mqh"
echo "copied to: $TARGET_FILE"
echo "copied model include to: $TARGET_DIR/CodexModelRecommendations.mqh"

"$ROOT_DIR/scripts/compile_mt5.sh" "$TARGET_FILE"

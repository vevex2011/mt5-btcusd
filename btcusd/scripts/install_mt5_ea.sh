#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EA_NAME="CodexTrendPullbackEA_BTCUSD"
SOURCE_FILE="$ROOT_DIR/ea/$EA_NAME.mq5"
SERVICE_NAME="CodexCalendarCacheService"
SHARED_SERVICES_DIR="${CODEX_MT5_SERVICES_SOURCE_DIR:-$(cd "$ROOT_DIR/.." && pwd)/services}"
SERVICE_SOURCE_FILE="$SHARED_SERVICES_DIR/$SERVICE_NAME.mq5"
SERVICE_INSTALL_SCRIPT="$SHARED_SERVICES_DIR/scripts/install_mt5_service.sh"
TARGET_DIR="${MT5_EXPERTS_DIR:-$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/CodexAutotrade}"
FILES_DIR="${MT5_FILES_DIR:-$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files}"
TELEGRAM_CONFIG_SOURCE="${CODEX_MT5_TELEGRAM_CONFIG:-$(cd "$ROOT_DIR/.." && pwd)/telegram.info}"
TARGET_FILE="$TARGET_DIR/$EA_NAME.mq5"

mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE"
cp "$ROOT_DIR/ea/CodexModelRecommendations.mqh" "$TARGET_DIR/CodexModelRecommendations.mqh"
echo "copied to: $TARGET_FILE"
echo "copied model include to: $TARGET_DIR/CodexModelRecommendations.mqh"

if [[ -f "$TELEGRAM_CONFIG_SOURCE" ]]; then
  mkdir -p "$FILES_DIR"
  cp "$TELEGRAM_CONFIG_SOURCE" "$FILES_DIR/telegram.info"
  echo "copied telegram config to: $FILES_DIR/telegram.info"
fi

if [[ -f "$SERVICE_SOURCE_FILE" && -f "$SERVICE_INSTALL_SCRIPT" ]]; then
  bash "$SERVICE_INSTALL_SCRIPT"
else
  echo "shared calendar service not found; skipping optional service install"
  echo "set CODEX_MT5_SERVICES_SOURCE_DIR to install it from an external services folder"
fi

"$ROOT_DIR/scripts/compile_mt5.sh" "$TARGET_FILE"

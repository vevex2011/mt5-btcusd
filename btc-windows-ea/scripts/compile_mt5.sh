#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 /absolute/path/to/file.mq5" >&2
  exit 1
fi

SOURCE_POSIX="$1"
if [[ ! -f "$SOURCE_POSIX" ]]; then
  echo "source file not found: $SOURCE_POSIX" >&2
  exit 1
fi

MT5_APP="${MT5_APP:-$HOME/Applications/MetaTrader 5.app}"
WINEPREFIX_DIR="${MT5_WINEPREFIX:-$HOME/Library/Application Support/net.metaquotes.wine.metatrader5}"
WINE_BIN="$MT5_APP/Contents/SharedSupport/wine/bin/wine64"
WINEPATH_BIN="$MT5_APP/Contents/SharedSupport/wine/bin/winepath"
EDITOR_EXE='C:\Program Files\MetaTrader 5\metaeditor64.exe'
BUILD_DIR="${CODEX_MT5_BUILD_DIR:-$WINEPREFIX_DIR/drive_c/codexbuild}"

if [[ ! -x "$WINE_BIN" ]]; then
  echo "wine runtime not found: $WINE_BIN" >&2
  exit 1
fi
if [[ ! -x "$WINEPATH_BIN" ]]; then
  echo "winepath not found: $WINEPATH_BIN" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"
BUILD_WIN="$(WINEPREFIX="$WINEPREFIX_DIR" "$WINEPATH_BIN" -w "$BUILD_DIR")"

SOURCE_BASENAME="$(basename "$SOURCE_POSIX")"
SOURCE_STEM="${SOURCE_BASENAME%.mq5}"
BUILD_SOURCE="$BUILD_DIR/$SOURCE_BASENAME"
BUILD_EX5="$BUILD_DIR/$SOURCE_STEM.ex5"
BUILD_LOG="$BUILD_DIR/$SOURCE_STEM.compile.log"
TARGET_EX5="$(cd "$(dirname "$SOURCE_POSIX")" && pwd)/$SOURCE_STEM.ex5"
TARGET_LOG="$(cd "$(dirname "$SOURCE_POSIX")" && pwd)/$SOURCE_STEM.compile.log"

cp "$SOURCE_POSIX" "$BUILD_SOURCE"
find "$(dirname "$SOURCE_POSIX")" -maxdepth 1 -type f -name '*.mqh' -exec cp {} "$BUILD_DIR/" \;
rm -f "$BUILD_EX5" "$BUILD_LOG" "$TARGET_EX5" "$TARGET_LOG"

COMPILE_ARG="/compile:${BUILD_WIN}\\${SOURCE_BASENAME}"
LOG_ARG="/log:${BUILD_WIN}\\${SOURCE_STEM}.compile.log"

WINEPREFIX="$WINEPREFIX_DIR" "$WINE_BIN" "$EDITOR_EXE" /portable "$COMPILE_ARG" "$LOG_ARG" || true

if [[ ! -f "$BUILD_EX5" ]]; then
  echo "compiled file not found: $BUILD_EX5" >&2
  if [[ -f "$BUILD_LOG" ]]; then
    echo "compile log: $BUILD_LOG" >&2
  fi
  exit 1
fi

cp "$BUILD_EX5" "$TARGET_EX5"
if [[ -f "$BUILD_LOG" ]]; then
  cp "$BUILD_LOG" "$TARGET_LOG"
fi

echo "compiled to: $TARGET_EX5"
echo "compile log: $TARGET_LOG"

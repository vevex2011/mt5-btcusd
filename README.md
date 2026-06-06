# MT5 BTCUSD

BTCUSD-only MT5 trading code split out from the larger research workspace.

This repository is for keeping the currently profitable BTCUSD line isolated
from multi-symbol experiments. It contains the Mac demo BTCUSD EAs, the Windows
small-account BTCUSD variants, and the current lightweight BTCUSD model artifact.

## Repository

Local path:

```text
/Users/xww/Documents/mt5-btcusd
```

Remote:

```text
git@github.com:vevex2011/mt5-btcusd.git
```

The larger research workspace remains at `/Users/xww/Documents/mt5`. Shared data
collection, PostgreSQL, dashboard, and non-BTC research stay there. BTCUSD
production code and model artifacts should be maintained here first.

## Layout

```text
btcusd/              Mac BTCUSD main model-direct EA
btcusd-pending/      Mac BTCUSD pending/model-direct EA
btc-windows-ea/      Windows small real-account BTCUSD EAs
models/              BTCUSD lightweight model artifact and recommendation sample
docs/                BTCUSD maintenance notes
```

## Current Production Idea

- Symbol: `BTCUSD`
- Model: `BTCUSD_PURE_PY_MLP`
- Training base: M1 short-horizon BTCUSD K-line features
- Runtime file: `codex-edge-model/symbols/BTCUSD.json`
- Execution: MT5 EA reads the model recommendation JSON and submits/manages
  BTCUSD trades.

The Mac demo account currently runs:

- `btcusd/ea/CodexTrendPullbackEA_BTCUSD.mq5`
- `btcusd-pending/ea/CodexPendingOrderEA_BTCUSD.mq5`

The Windows small real-account experiment uses:

- `btc-windows-ea/ea/CodexBTCWindowsLightEA.mq5`
- `btc-windows-ea/ea/CodexBTCWindowsPendingEA.mq5`

## Sensitive Files

Do not commit live credentials or local runtime files:

- `telegram.info`
- `sub2api.conf`
- `.env`
- `*.local.ps1`
- MT5 screenshots, generated context JSON, logs, and compiled `.ex5` files

## Model Files

`models/deep_short_model_btcusd.json` is the current lightweight BTCUSD model
artifact used for the BTCUSD production line.

`models/BTCUSD.recommendation.example.json` is a small example of the exported
runtime recommendation shape. The live EA normally reads from the MT5 sandbox,
not from this repository path.

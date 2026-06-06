# BTC Windows Light EA

This directory is a separate BTCUSD real-account experiment for the Windows MT5
machine. It is intentionally isolated from `btcusd` and `btcusd-pending`.

## Goal

- Trade only `BTCUSD`.
- Use the per-symbol lightweight model (`BTCUSD_PURE_PY_MLP`) exported through
  `edge_recommendations.json`.
- Keep the Windows small real account independent from the Mac feedback loop for
  now. The Windows inference process may read/write model prediction rows in the
  research database, but Windows real trade/deal logs should not be imported
  into the Mac training database until we decide to merge them.

## EA Defaults

`CodexBTCWindowsLightEA` is the trend-model EA variant.

- Symbol guard: `BTCUSD` only.
- Signal timeframe: `M1`.
- Higher-timeframe trend filter: disabled.
- Model source: required, per-symbol lightweight model.
- Minimum model probability: `0.62`.
- Max model recommendation age: `180` seconds.
- Risk per trade: `0.10%`.
- Max volume per trade: `0.01`.
- Minimum equity to trade: `80 USD`.
- Daily closed-loss stop: `3 USD`.
- Consecutive closed-loss stop: `2`.
- Max same-direction positions: `1`.
- News filter: disabled.
- Shared coexistence guard with the pending EA:
  - peer pending model magic: `2026052625`;
  - max combined BTC positions: `2`;
  - max combined BTC volume: `0.02`;
  - opposite-direction BTC positions are blocked.

These defaults are intentionally conservative because the target account is
small and real.

`CodexBTCWindowsPendingEA` is the pending/model-direct variant derived from
`btcusd-pending`. It is installed alongside the light EA and can be attached on a
second BTCUSD M1 chart to make the small real-account experiment closer to the
demo environment. Its Windows defaults are:

- Symbol guard: `BTCUSD` only.
- Signal timeframe: `M1`.
- AI chart-line suggestions: disabled.
- Chart-line/manual pending modes: disabled.
- Rule pending modes: disabled.
- Model direct trading: enabled.
- Model source: required, per-symbol lightweight model.
- Max volume per trade: `0.01`.
- Minimum equity to trade: `80 USD`.
- Daily closed-loss stop: `3 USD`.
- Consecutive closed-loss stop: `2`.
- Independent magic numbers: `2026052621` through `2026052625`.
- Shared coexistence guard with the trend EA:
  - peer trend magic: `2026052601`;
  - max combined BTC positions: `2`;
  - max combined BTC volume: `0.02`;
  - opposite-direction BTC positions are blocked.

## Windows Setup

1. Copy or pull this directory to the Windows repo, for example:

   `D:\workspace\mt5\BTC_WINDOWS_EA`

2. Copy the current BTC lightweight model to:

   `D:\workspace\mt5\CodexMT5\models\deep_short_model_btcusd.json`

3. Create a private Windows config file. Do not commit it:

   `D:\workspace\mt5\BTC_WINDOWS_EA\btc_windows_live.local.ps1`

   Example:

   ```powershell
   $env:PGHOST = "100.108.104.105"
   $env:PGPORT = "5432"
   $env:PGDATABASE = "mt5_edge"
   $env:PGUSER = "xww"
   $env:PGPASSWORD = "your-local-db-password"
   ```

4. Install and compile the EA into Windows MT5:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install_windows_mt5.ps1
   ```

5. Start the live inference loop:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_windows_btc_light_live_loop.ps1 -ConfigFile .\btc_windows_live.local.ps1
   ```

6. Optional: register the inference loop as a Windows startup task:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install_windows_btc_light_task.ps1 -ConfigFile .\btc_windows_live.local.ps1
   ```

## MT5 Notes

Attach `CodexBTCWindowsLightEA` and, if desired, `CodexBTCWindowsPendingEA` on
two separate BTCUSD M1 charts on the Windows real account. Keep algo trading
enabled only after checking:

- the account is the intended small real account,
- `InpMaxVolumePerTrade` is still `0.01`,
- `InpMaxCombinedBTCPositions` is still `2`,
- `InpMaxCombinedBTCVolume` is still `0.02`,
- `InpModelRecommendationFile` points to
  `codex-edge-model\edge_recommendations.json`,
- Telegram settings are correct if alerting is desired.

# BTCUSD Standalone Maintenance

## Goal

Keep BTCUSD isolated because it is currently the strongest live-performing
symbol in the system. Other symbols and heavy EURUSD tick research should not
change BTCUSD production behavior accidentally.

## Repository Location

```text
/Users/xww/Documents/mt5-btcusd
git@github.com:vevex2011/mt5-btcusd.git
```

The original multi-symbol workspace remains at:

```text
/Users/xww/Documents/mt5
```

Use the standalone repository for BTCUSD production maintenance. Use the larger
workspace for shared data infrastructure, dashboard work, and non-BTC research.

## Maintenance Rule

- Keep BTCUSD EA changes in this repository first.
- Keep BTCUSD model artifacts and recommendation examples under `models/`.
- Do not mix experimental multi-symbol feature changes into BTCUSD production
  unless they have been tested on BTCUSD directly.
- Preserve the `btcusd-high-model` snapshot in the original workspace as a
  rollback reference.

## Runtime Flow

```text
M1 BTCUSD data -> BTCUSD_PURE_PY_MLP inference -> BTCUSD.json recommendation
-> BTCUSD EA execution -> MT5 trade/deal logs -> dashboard/database observation
```

## Mac Demo Deployment

Use the scripts inside each Mac EA directory:

```bash
cd btcusd
./scripts/install_mt5_ea.sh

cd ../btcusd-pending
./scripts/install_mt5_ea.sh
```

Important: install the two Mac EAs sequentially. They both contain a file named
`CodexModelRecommendations.mqh`, so parallel compilation can cause one compile
to read the other EA's include file.

## Windows Small Account Deployment

Use the scripts in `btc-windows-ea/scripts/`. The Windows variant is deliberately
more conservative than the Mac demo setup:

- max volume per trade: `0.01`
- minimum equity guard: `80 USD`
- lower risk per trade
- shared BTC position/volume guard between trend and pending variants

## Capital Notes

For an unmodified Mac BTCUSD setup copied to another MT5 account, the practical
minimum is much higher than the mathematical minimum because broker minimum lot
size can distort model risk.

For BTCUSD only:

- `100 USD`: possible only as an aggressive small-account experiment.
- `600-1000 USD`: more realistic minimum for unmodified Mac BTCUSD behavior.
- `1000+ USD`: preferred minimum if both main and pending BTCUSD EAs are active.

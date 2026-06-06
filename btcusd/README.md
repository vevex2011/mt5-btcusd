# BTCUSD MT5 Trend Following EA

一个面向 `MetaTrader 5 demo account` 的趋势跟随实验仓库，包含：

- 一个 `MQL5 Expert Advisor`
- 一个 `Go` 统计工具
- 一组安装、编译和回测脚本

这个项目只用于研究、回测和 demo 盘测试，不构成收益承诺，也不建议直接用于真实资金。

## Project Layout

```text
ea/            EA 源码
cmd/           Go 统计工具
config/        分析和过滤配置
scripts/       安装、编译、回测脚本
```

主 EA 文件：

`ea/CodexTrendPullbackEA_BTCUSD.mq5`

## Strategy Summary

当前版本是一个以 `M30` 为执行周期、以更高周期过滤大方向的趋势策略。

核心逻辑：

- 信号周期：`M30`
- 高周期趋势过滤：默认启用 `H4`
- 趋势基线：`H4 EMA50` 相对 `H4 EMA200`
- 快慢线：`EMA20 / EMA50`
- 动量过滤：`RSI(14)`
- 波动尺子：`ATR(14)`

当前启用的入场模块：

- `PULLBACK`
  - 默认使用二次确认回踩后再入场

当前额外启用的过滤：

- `RANGING FILTER`
  - 要求 `EMA20/EMA50` 间距和 `EMA50` 斜率都达到最小 ATR 阈值

当前保留但未接入主信号路径的参数：

- `FIRST_LEG`
  - 主信号未出现时作为可选突破入场模块，BTCUSD 默认关闭

当前默认关闭的模块：

- `CONTINUATION`
  - 早期测试里这类延续追单在震荡段表现较差，所以默认关闭

## Risk Management

默认风控参数：

- 单笔风险：`0.30%`
- 初始止损：`1.8 x ATR`
- 初始止盈：`1.50R`
- 保本触发：`1.00R`
- 跟踪止损：`1.30R` 后以 `0.80R` 跟踪
- 盈利锁定触发：`0.90R`
- 默认锁盈：`0.20R`
- 日内最大亏损：`2.00%`
- 经济日历过滤：由 `CodexCalendarCacheService` 每 `300` 秒缓存一次 MT5 经济日历，EA 只读取共享缓存并避开 `USD` 高重要性事件前 `90` 分钟、后 `45` 分钟的新开仓
- 最大点差：`5000 points` 且不超过 `0.08 x ATR`
- 同方向最大持仓数：`2`
- 同方向加仓：默认关闭；开启时要求已有仓位保本/锁盈或至少 `0.80R` 浮盈
- 止损后冷却：`4` 根信号周期 K 线

额外说明：

- 小资金账户启用了最小手数兜底
- 默认关闭交易时段限制，全天可交易
- 本目录默认针对 `BTCUSD M30`，EA 会拒绝挂到非 BTCUSD 前缀的图表

## Telegram Alerts

EA 支持下单成功后发送 Telegram 通知，默认开启。

- `InpTelegramEnabled=true` 但 token 或 chat id 为空时只跳过通知，不影响交易
- `InpTelegramEnabled=false` 时完全不发送通知
- token 或 chat id 为空时只跳过通知，不影响交易
- token、chat id 填错或 WebRequest 失败时只写日志，不会撤单，也不会阻止后续交易逻辑
- 开启前需要在 MT5 `工具 -> 选项 -> EA交易 -> 允许 WebRequest` 添加 `https://api.telegram.org`；可以只维护工作区根目录的 `telegram.info`，安装脚本会复制到 MT5 `MQL5/Files/telegram.info`，EA 启动时会从里面读取 `env`、`token`、`chat_id` 和 `url`
- 不要把真实 Telegram bot token 提交到 git

## EA Input Reference

下面是当前版本最常用的输入参数分组说明。

### Trend Filter

| Input | Default | Meaning |
| --- | --- | --- |
| `InpSignalTimeframe` | `PERIOD_M30` | 执行和判定信号的周期 |
| `InpUseHigherTimeframeTrendFilter` | `true` | 是否启用更高周期方向过滤 |
| `InpTrendFilterTimeframe` | `PERIOD_H4` | 大方向过滤周期 |
| `InpTrendConfirmBars` | `3` | 趋势确认用的高周期 K 线数量 |
| `InpTrendBaselineMAPeriod` | `200` | 高周期基线均线周期 |
| `InpMinTrendSpreadATR` | `0.00` | 震荡过滤中要求的最小均线间距 ATR 倍数，默认不因间距过小拦截 |
| `InpMinSlowMASlopeATR` | `0.00` | 震荡过滤中要求的最小慢线斜率 ATR 倍数，默认不因斜率过小拦截 |
| `InpFastMAPeriod` | `20` | 信号周期快线 |
| `InpSlowMAPeriod` | `50` | 信号周期慢线 |

### Entry Modules

| Input | Default | Meaning |
| --- | --- | --- |
| `InpEnableFirstLegEntry` | `true` | 是否启用第一脚突破入场 |
| `InpFirstLegBreakoutLookback` | `2` | 第一脚突破回看参数 |
| `InpFirstLegLongRSIMin` | `45.0` | 第一脚做多最小 RSI |
| `InpFirstLegLongRSIMax` | `65.0` | 第一脚做多最大 RSI |
| `InpFirstLegShortRSIMin` | `35.0` | 第一脚做空最小 RSI |
| `InpFirstLegShortRSIMax` | `55.0` | 第一脚做空最大 RSI |
| `InpPullbackLongRSIMin` | `50.0` | 回踩做多最小 RSI |
| `InpPullbackLongRSIMax` | `72.0` | 回踩做多最大 RSI |
| `InpPullbackShortRSIMin` | `28.0` | 回踩做空最小 RSI |
| `InpPullbackShortRSIMax` | `50.0` | 回踩做空最大 RSI |
| `InpRequireSecondPullbackConfirmation` | `true` | 回踩模块是否要求二次确认 K 线再入场 |

### Legacy Continuation Inputs

| Input | Default | Meaning |
| --- | --- | --- |
| `InpEnableContinuationEntry` | `false` | 为兼容旧参数保留，但当前代码逻辑已移除 |
| `InpContinuationBreakoutLookback` | `3` | 旧版 continuation 参数，占位保留 |
| `InpContinuationLongRSIMin` | `58.0` | 旧版 continuation 参数，占位保留 |
| `InpContinuationLongRSIMax` | `78.0` | 旧版 continuation 参数，占位保留 |
| `InpContinuationShortRSIMin` | `24.0` | 旧版 continuation 参数，占位保留 |
| `InpContinuationShortRSIMax` | `42.0` | 旧版 continuation 参数，占位保留 |

### Telegram Alerts

| Input | Default | Meaning |
| --- | --- | --- |
| `InpTelegramEnabled` | `true` | 是否在下单成功后发送 Telegram 通知 |
| `InpTelegramConfigFile` | `telegram.info` | 从 MT5 `MQL5/Files` 读取的 Telegram 配置文件 |
| `InpTelegramApiURL` | `""` | Telegram API 地址；为空时优先用配置文件 `url`，再默认 `https://api.telegram.org` |
| `InpTelegramEnv` | `""` | Telegram 消息环境标识；为空时读取配置文件 `env`，例如 `test` / `live` |
| `InpTelegramBotToken` | `""` | Telegram Bot Token，留空时优先读取配置文件 `token`，仍为空才跳过通知 |
| `InpTelegramChatID` | `""` | Telegram Chat ID，留空时优先读取配置文件，仍为空则跳过通知 |
| `InpTelegramTimeoutMs` | `5000` | Telegram WebRequest 超时时间；失败不影响交易 |

### Position Management

| Input | Default | Meaning |
| --- | --- | --- |
| `InpAllowAddOnEntry` | `false` | 是否允许同方向加仓 |
| `InpMaxPositionsPerDirection` | `2` | 同方向最大持仓数 |
| `InpAddOnMinProfitR` | `0.80` | 允许第二笔同向加仓前，第一笔至少要达到的浮盈 R 倍数 |
| `InpStopLossCooldownBars` | `4` | 止损后，同方向需要冷却的信号周期 K 线数 |
| `InpMagicNumber` | `2026050601` | EA 魔术号 |

### Risk And Exits

| Input | Default | Meaning |
| --- | --- | --- |
| `InpRiskPerTradePercent` | `0.30` | 单笔目标风险占账户百分比 |
| `InpRSIPeriod` | `14` | RSI 周期 |
| `InpATRPeriod` | `14` | ATR 周期 |
| `InpTrendATRStopMultiplier` | `0.90` | 高周期 ATR 参与止损参考时使用的倍率 |
| `InpStopLossATR` | `1.80` | 初始止损倍数 |
| `InpTakeProfitRewardRisk` | `1.50` | 初始止盈按初始风险距离计算的 RR 倍数 |
| `InpBreakEvenTriggerR` | `1.00` | 推到保本的浮盈 R 倍数 |
| `InpTrailStartR` | `1.30` | 启动跟踪止损的浮盈 R 倍数 |
| `InpTrailDistanceR` | `0.80` | 跟踪止损距离 R 倍数 |
| `InpProfitLockTriggerR` | `0.90` | 浮盈达到多少 R 开始锁盈 |
| `InpProfitLockAmountR` | `0.20` | 目标锁定利润 R 倍数 |
| `InpRemoveTakeProfitOnLock` | `false` | 锁盈后是否移除固定 TP |
| `InpRemoveTakeProfitTriggerR` | `1.20` | 触发移除固定 TP 的浮盈 R 倍数 |
| `InpMaxSpreadPoints` | `5000` | 超过该点差不进场 |
| `InpMaxSpreadATR` | `0.08` | 点差超过信号周期 ATR 该比例时不进场 |
| `InpMaxDailyLossPercent` | `2.00` | 日内最大亏损阈值 |
| `InpUseEconomicCalendarFilter` | `false` | 是否启用 MT5 经济日历过滤，只阻止新开仓 |
| `InpCalendarCurrencies` | `USD` | 需要关注的日历货币，多个货币可用逗号或分号分隔 |
| `InpCalendarMinImportance` | `CALENDAR_IMPORTANCE_HIGH` | 触发过滤的最低事件重要性 |
| `InpCalendarPreEventMinutes` | `90` | 事件公布前多少分钟停止新开仓 |
| `InpCalendarPostEventMinutes` | `45` | 事件公布后多少分钟继续停止新开仓 |
| `InpCalendarRefreshSeconds` | `300` | 旧参数兼容保留；EA 不再使用它刷新日历 |
| `InpCalendarCachePrefix` | `CodexCalendarCache.USD` | EA 读取的 MT5 全局变量缓存前缀 |
| `InpCalendarCacheMaxAgeSeconds` | `900` | 缓存超过该秒数时视为过期 |
| `InpCalendarCacheMaxEvents` | `64` | EA 最多读取的缓存事件数量 |
| `InpBlockOnCalendarError` | `false` | 日历查询失败时是否保守阻止新开仓 |
| `InpUseMinVolumeFallback` | `true` | 小资金时是否尝试最小手数兜底 |
| `InpMaxFallbackRiskPercent` | `1.00` | 最小手数兜底时允许的最大有效风险 |

### Session And UI

| Input | Default | Meaning |
| --- | --- | --- |
| `InpUseTradingHours` | `false` | 是否启用交易时段限制 |
| `InpTradeStartHour` | `8` | 启用交易时段限制时的起始小时 |
| `InpTradeEndHour` | `22` | 启用交易时段限制时的结束小时 |
| `InpAllowLong` | `true` | 是否允许做多 |
| `InpAllowShort` | `true` | 是否允许做空 |
| `InpTargetSymbol` | `BTCUSD` | 允许挂载的目标品种前缀 |
| `InpEnforceTargetSymbol` | `true` | 是否强制检查当前图表品种 |
| `InpShowIndicators` | `true` | 挂载时是否自动显示均线和指标 |
| `InpLogFolder` | `codex-mt5-btcusd` | 交易日志输出目录 |
| `InpVerboseLogs` | `true` | 是否打印更详细的运行日志 |

## Install

本机 MT5 Experts 目录默认是：

`/Users/xww/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts`

安装脚本：

```bash
chmod +x ./scripts/compile_mt5.sh ./scripts/install_mt5_ea.sh
./scripts/install_mt5_ea.sh
```

安装后目标文件一般会复制到：

`/Users/xww/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/CodexAutotrade/CodexTrendPullbackEA_BTCUSD.mq5`

共享日历 Service 源码位于工作区顶层 `services/` 目录，安装脚本会从那里复制到：

`/Users/xww/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Services/CodexAutotrade/CodexCalendarCacheService.mq5`

安装脚本也会复制 Telegram 配置文件：`/Users/xww/Documents/mt5/telegram.info` -> MT5 `MQL5/Files/telegram.info`。

## Compile Notes

这个仓库主要跑在 `Wine + macOS` 的 MT5 环境上。命令行编译有时会出现“日志看起来成功，但没有真正生成新 `.ex5`”的情况。

如果安装脚本复制成功，但没有产出新的 `.ex5`，最稳的办法是：

1. 打开 `MetaEditor`
2. 打开 `CodexTrendPullbackEA_BTCUSD.mq5`
3. 按一次 `F7`

脚本：

- `scripts/compile_mt5.sh`
- `scripts/install_mt5_ea.sh`

## Run In MT5

手动挂载步骤：

1. 打开 `MetaTrader 5`
2. 在导航器里找到 `Services > CodexAutotrade > CodexCalendarCacheService` 并启动
3. 在导航器里找到 `Experts > CodexAutotrade > CodexTrendPullbackEA_BTCUSD`
4. 拖到 `BTCUSD, M30` 图表
5. 勾选允许 Algo Trading
6. 打开顶部 `Algo Trading`

更建议的顺序是：

1. 先回测
2. 再 demo 挂图
3. 最后才长时间观察

## Backtest

最近一个月回测脚本：

```bash
./scripts/run_mt5_backtest.sh
```

默认回测参数：

- Symbol: `BTCUSD`
- Timeframe: `M30`
- Range: `2026-02-19` 到 `2026-03-19`
- Starting balance: `10000 USD`

报告会输出到 MT5 的 `Reports` 目录。

## Trade Logs

EA 成交会写到：

`/Users/xww/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/codex-mt5-btcusd/CodexTrendPullbackEA-BTCUSD-deals.tsv`

## Performance Report

用 Go 工具汇总结果：

```bash
go run ./cmd/dealreport \
  -input "/Users/xww/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/codex-mt5-btcusd/CodexTrendPullbackEA-BTCUSD-deals.tsv" \
  -starting-balance 10000
```

按日期区间统计：

```bash
go run ./cmd/dealreport \
  -input "/Users/xww/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/codex-mt5-btcusd/CodexTrendPullbackEA-BTCUSD-deals.tsv" \
  -from 2026-03-19 \
  -to 2026-04-19 \
  -starting-balance 10000
```

`dealreport` 默认会读取：

`config/ignored_trade_ids.txt`

这样可以把手动干预单从策略统计里排除掉。

### dealreport Flags

| Flag | Meaning |
| --- | --- |
| `-input` | 必填，TSV 成交文件路径 |
| `-from` | 起始日期，格式 `YYYY-MM-DD` |
| `-to` | 结束日期，格式 `YYYY-MM-DD` |
| `-symbol` | 只统计一个品种，比如 `BTCUSD` |
| `-magic` | 只统计某个 magic number |
| `-starting-balance` | 用于计算收益率 |
| `-ignore-file` | 自定义忽略 ID 文件路径 |

## Latest Demo Snapshot

最近一次巡检（`2026-04-10`）的结论如下：

- EA: `CodexTrendPullbackEA_BTCUSD`（`BTCUSD M30`）
- 成交文件最新平仓时间：`2026.04.09 21:02:24`
- 当前状态：EA 正常运行，日志中多次出现 `Skipping entry: ranging regime`，表示当前主要被震荡过滤器拦截进场
- 风控与交易开关：未发现 `calculated volume is below minimum`、自动交易关闭或其他硬错误

监控重点文件：

- 成交文件：`/Users/xww/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/codex-mt5-btcusd/CodexTrendPullbackEA-BTCUSD-deals.tsv`
- 终端日志：`/Users/xww/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Logs/`

输出内容包括：

- 净收益
- 毛利润和毛亏损
- 胜率
- 平均盈利和平均亏损
- Profit Factor
- 最近平仓记录

## Known Limitations

- `Wine` 下命令行编译不稳定，必要时要手动 `F7`
- MT5 图表和终端状态容易受本地 UI 操作影响
- demo 回测和 live demo 的成交结果不会完全一致
- 当前版本仍在迭代，参数还在根据实际 demo 表现持续调整

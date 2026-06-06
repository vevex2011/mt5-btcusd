#property copyright "Codex Autotrade"
#property version   "1.00"
#property strict
#property description "BTCUSD Windows real-account pending-model EA with strict small-account risk guards."

#include <Trade/Trade.mqh>

enum TradeSignal
{
   SIGNAL_NONE = 0,
   SIGNAL_BUY = 1,
   SIGNAL_SELL = -1
};

input string          InpTargetSymbol = "BTCUSD";
input bool            InpEnforceTargetSymbol = true;
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_M1;
input ENUM_TIMEFRAMES InpTrendTimeframe = PERIOD_H1;
input ENUM_TIMEFRAMES InpChartLineTimeframe = PERIOD_D1;

input bool            InpDryRun = false;
input bool            InpEnableChartLineTrading = false;
input bool            InpUseCommonChartLineIndicators = false;
input string          InpCommonIndicatorInactiveSuffix = "_INIT";
input bool            InpAutoCreateChartLines = false;
input bool            InpAutoUpdateChartLines = false;
input bool            InpAutoCreateBothDirections = false;
input bool            InpAutoRemoveInactiveDirection = false;
input bool            InpAutoCreateChartLinesRequireTrendFilter = true;
input bool            InpSkipChartLineOrdersOnFreshAutoCreate = true;
input bool            InpSelectAutoCreatedChartLines = true;
input bool            InpShowChartLineLabels = false;
input int             InpChartLineLabelBarsBack = 2;
input bool            InpPauseAutoModesWhenChartLinesExist = true;
input bool            InpChartLineRequireTrendFilter = false;
input bool            InpChartLineRequireH4EMA200Slope = false;
input double          InpChartLineH4EMA200SlopeMinATR = 0.000;
input int             InpChartLineCheckSeconds = 10;
input int             InpMaxChartLinePendingOrders = 4;
input int             InpMaxChartLinePositionsPerMode = 1;
input int             InpChartLineExpiryBars = 8;
input bool            InpEnableAIChartLineSuggestions = false;
input string          InpAIChartLineSuggestionFile = "codex_ai_lines_btcusd.json";
input bool            InpAIChartLineUseCommonFiles = false;
input int             InpAIChartLineCheckSeconds = 30;
input int             InpAIChartLineSuggestionMaxAgeSeconds = 900;
input bool            InpAIChartLineRequireFreshTimestamp = true;
input bool            InpAIChartLineRequireSymbolMatch = true;
input bool            InpAIRemoveOmittedChartLines = true;
input bool            InpAIKeepOmittedSameDirectionLines = true;
input int             InpAIKeepOmittedSameDirectionSeconds = 14400;
input int             InpAILimitFillNudgePoints = 100;
input bool            InpEnableAIBacktestReplay = false;
input string          InpAIBacktestReplayFile = "codex_ai_lines_btcusd_replay.csv";
input bool            InpAIBacktestReplayUseCommonFiles = false;
input int             InpAIBacktestReplayMaxAgeSeconds = 14400;
input bool            InpPauseAutoModesWhenAIChartLineSuggestionsEnabled = true;
input bool            InpExportAIChartLineContext = false;
input string          InpAIChartLineContextFile = "codex_btcusd_market_context.json";
input int             InpAIChartLineContextExportSeconds = 60;
input bool            InpExportAIH4Screenshot = false;
input ENUM_TIMEFRAMES InpAIH4ScreenshotTimeframe = PERIOD_H4;
input string          InpAIH4ScreenshotFile = "codex_btcusd_h4.png";
input int             InpAIH4ScreenshotWidth = 1280;
input int             InpAIH4ScreenshotHeight = 720;
input int             InpAIH4ScreenshotExportSeconds = 300;
input double          InpAIH4EMA200SlopeMinATR = 0.000;
input bool            InpEnableLimitReversion = false;
input bool            InpEnableStopBreakout = false;
input bool            InpEnableStopLimitRetest = false;
input int             InpMaxManagedPendingOrders = 6;
input int             InpMaxPendingOrdersPerMode = 1;

input bool            InpUseModelDirectTrading = true;
input string          InpModelRecommendationFile = "codex-edge-model\\edge_recommendations.json";
input bool            InpUseModelRecommendationFilter = true;
input bool            InpAllowTradeWhenModelMissing = false;
input int             InpModelMaxAgeSeconds = 180;
input bool            InpModelUseDirectionBias = true;
input double          InpModelDirectionMinConfidence = 0.60;
input bool            InpModelUseShortRuleScore = true;
input int             InpModelMinDirectionSamples = 50;
input double          InpModelMinDirectionScore = 1.50;
input double          InpModelOppositeTopScoreBlock = 2.40;
input bool            InpModelUseFrequencyThrottle = true;
input int             InpModelLowFrequencyCooldownMinutes = 120;
input int             InpModelNormalFrequencyCooldownMinutes = 30;
input int             InpModelHighFrequencyCooldownMinutes = 0;
input bool            InpModelDirectUseTopRule = false;
input bool            InpModelDirectPreferDeepModel = true;
input bool            InpModelDirectRequireDeepModel = true;
input double          InpDeepModelMinProbability = 0.62;
input double          InpDeepModelMinConfidence = 0.10;
input bool            InpModelDirectRequireDailyDirection = false;
input int             InpModelDirectMinSamples = 0;
input double          InpModelDirectMinScore = 0.00;
input bool            InpModelRequirePositiveNetExpectancy = true;
input double          InpModelMinNetExpectancyATR = 0.02;
input bool            InpUseModelExecutionPlan = true;
input bool            InpModelExecutionPreferDeepModel = true;
input double          InpModelExecutionMinRiskPercent = 0.05;
input double          InpModelExecutionMaxRiskPercent = 0.25;
input double          InpModelExecutionMinStopATR = 0.20;
input double          InpModelExecutionMaxStopATR = 2.50;
input double          InpModelExecutionMinTargetATR = 0.20;
input double          InpModelExecutionMaxTargetATR = 4.00;
input bool            InpModelExecutionUseTrailing = true;
input double          InpModelExecutionMinTrailATR = 0.05;
input double          InpModelExecutionMaxTrailATR = 3.00;
input bool            InpModelTimeExitEnabled = true;
input double          InpModelTimeExitGraceMultiplier = 1.00;
input int             InpModelTimeExitMinMinutes = 15;
input int             InpMaxModelDirectPositionsPerDirection = 1;
input bool            InpModelDirectBlockOppositePositions = true;
input bool            InpModelDirectCancelManagedPendingOrders = true;

input ulong           InpLimitMagicNumber = 2026052621;
input ulong           InpStopMagicNumber = 2026052622;
input ulong           InpStopLimitMagicNumber = 2026052623;
input ulong           InpChartLineMagicNumber = 2026052624;
input ulong           InpModelDirectMagicNumber = 2026052625;
input bool            InpWindowsCoexistenceMode = true;
input ulong           InpPeerTrendMagicNumber = 2026052601;
input int             InpMaxCombinedBTCPositions = 2;
input double          InpMaxCombinedBTCVolume = 0.02;
input bool            InpBlockOppositeCoexistencePositions = true;

input string          InpBuyPullbackLineName = "BTC_BUY_PULLBACK";
input string          InpSellPullbackLineName = "BTC_SELL_PULLBACK";
input string          InpBuyBreakoutLineName = "BTC_BUY_BREAKOUT";
input string          InpSellBreakdownLineName = "BTC_SELL_BREAKDOWN";
input string          InpBuyBreakoutTriggerLineName = "BTC_BUY_BREAKOUT_TRIGGER";
input string          InpBuyRetestEntryLineName = "BTC_BUY_RETEST_ENTRY";
input string          InpSellBreakdownTriggerLineName = "BTC_SELL_BREAKDOWN_TRIGGER";
input string          InpSellRetestEntryLineName = "BTC_SELL_RETEST_ENTRY";

input color           InpChartLineBuyColor = clrDodgerBlue;
input color           InpChartLineSellColor = clrTomato;
input color           InpChartLineStopLimitEntryColor = clrGold;

input int             InpFastMAPeriod = 20;
input int             InpSlowMAPeriod = 50;
input int             InpTrendBaselineMAPeriod = 200;
input int             InpRSIPeriod = 14;
input int             InpATRPeriod = 14;
input int             InpBreakoutLookbackBars = 8;
input int             InpTrendConfirmBars = 2;

input double          InpRiskPerOrderPercent = 0.10;
input double          InpMaxVolumePerTrade = 0.01;
input double          InpMinEquityToTrade = 80.00;
input double          InpMaxDailyLossMoney = 3.00;
input int             InpMaxConsecutiveLosses = 2;
input bool            InpUseMinVolumeFallback = true;
input double          InpMaxFallbackRiskPercent = 5.00;
input double          InpStopLossATR = 1.20;
input double          InpTakeProfitRewardRisk = 1.50;
input bool            InpEnableProfitFloorStop = true;
input double          InpProfitFloorArmMoney = 1.00;
input double          InpProfitFloorLockMoney = 0.60;
input double          InpProfitFloorStepMoney = 0.60;
input bool            InpProfitFloorRemoveTakeProfit = true;
input bool            InpEnableMaxLossStop = true;
input int             InpMaxLossStopPoints = 30000;

input double          InpLimitOffsetATR = 0.10;
input double          InpStopEntryOffsetATR = 0.05;
input double          InpStopLimitRetestATR = 0.35;
input double          InpMinTrendSpreadATR = 0.00;
input double          InpMinSlowMASlopeATR = 0.00;
input int             InpOrderExpiryBars = 4;

input int             InpMaxSpreadPoints = 5000;
input double          InpMaxSpreadATR = 0.08;
input int             InpDeviationPoints = 50;

input bool            InpUseEconomicCalendarFilter = false;
input bool            InpBlockOnCalendarError = false;
input int             InpCalendarPreEventMinutes = 90;
input int             InpCalendarPostEventMinutes = 45;
input string          InpCalendarCachePrefix = "CodexCalendarCache.USD";
input int             InpCalendarCacheMaxAgeSeconds = 900;
input int             InpCalendarCacheMaxEvents = 64;

input string          InpLogFolder = "codex-mt5-btc-windows-pending";
input bool            InpVerboseLogs = true;
input bool            InpTelegramEnabled = true;
input string          InpTelegramConfigFile = "telegram.info";
input string          InpTelegramApiURL = "";
input string          InpTelegramEnv = "";
input string          InpTelegramBotToken = "";
input string          InpTelegramChatID = "";
input int             InpTelegramTimeoutMs = 5000;

#include "CodexPendingModelRecommendations.mqh"

struct PendingPlan
{
   ENUM_ORDER_TYPE type;
   ulong           magic;
   string          mode;
   double          volume;
   double          price;
   double          stoplimit;
   double          sl;
   double          tp;
   datetime        expiration;
   string          comment;
   double          stop_distance;
   double          risk_percent;
   bool            used_min_volume_fallback;
};

CTrade trade;

int fast_ma_handle = INVALID_HANDLE;
int slow_ma_handle = INVALID_HANDLE;
int rsi_handle = INVALID_HANDLE;
int atr_handle = INVALID_HANDLE;
int chart_line_fast_ma_handle = INVALID_HANDLE;
int chart_line_slow_ma_handle = INVALID_HANDLE;
int chart_line_atr_handle = INVALID_HANDLE;
int trend_slow_ma_handle = INVALID_HANDLE;
int trend_baseline_ma_handle = INVALID_HANDLE;
int trend_atr_handle = INVALID_HANDLE;
bool use_manual_indicator_values = false;

datetime last_signal_bar_time = 0;
datetime last_chart_line_check_time = 0;
datetime last_ai_chart_line_check_time = 0;
datetime last_ai_chart_line_context_export_time = 0;
datetime last_ai_h4_screenshot_export_time = 0;
datetime last_inactive_chart_line_log_time = 0;
bool warned_symbol_mismatch = false;
bool warned_ai_suggestion_file_missing = false;
bool warned_ai_backtest_replay_file_missing = false;
string last_ai_chart_line_signature = "";
string chart_line_dry_run_signatures[];
string log_file_name = "";
string signal_log_file_name = "";
string telegram_api_url = "";
string telegram_env = "";
string telegram_bot_token = "";
string telegram_chat_id = "";

int OnInit()
{
   if(!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   fast_ma_handle = iMA(_Symbol, InpSignalTimeframe, InpFastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   slow_ma_handle = iMA(_Symbol, InpSignalTimeframe, InpSlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   rsi_handle = iRSI(_Symbol, InpSignalTimeframe, InpRSIPeriod, PRICE_CLOSE);
   atr_handle = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);
   chart_line_fast_ma_handle = iMA(_Symbol, InpChartLineTimeframe, InpFastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   chart_line_slow_ma_handle = iMA(_Symbol, InpChartLineTimeframe, InpSlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   chart_line_atr_handle = iATR(_Symbol, InpChartLineTimeframe, InpATRPeriod);
   trend_slow_ma_handle = iMA(_Symbol, InpTrendTimeframe, InpSlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   trend_baseline_ma_handle = iMA(_Symbol, InpTrendTimeframe, InpTrendBaselineMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   trend_atr_handle = iATR(_Symbol, InpTrendTimeframe, InpATRPeriod);

   if(!IndicatorHandlesReady())
   {
      Print("Failed to create one or more indicator handles. error=", GetLastError());
      if(!(bool)MQLInfoInteger(MQL_TESTER))
         return INIT_FAILED;

      Print("Strategy Tester fallback: calculating MA/RSI/ATR values from rates.");
      use_manual_indicator_values = true;
      ReleaseAllIndicatorHandles();
   }

   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   FolderCreate(InpLogFolder);
   log_file_name = InpLogFolder + "\\CodexPendingOrderEA-BTCUSD-deals.tsv";
   signal_log_file_name = InpLogFolder + "\\CodexPendingOrderEA-BTCUSD-signals.tsv";
   LoadTelegramSettings();

   Print("CodexPendingOrderEA_BTCUSD initialized. symbol=", _Symbol,
         ", signal_tf=", EnumToString(InpSignalTimeframe),
         ", trend_tf=", EnumToString(InpTrendTimeframe),
         ", chart_line_tf=", EnumToString(InpChartLineTimeframe),
         ", dry_run=", BoolToText(InpDryRun),
         ", chart_line_trading=", BoolToText(InpEnableChartLineTrading),
         ", common_chart_line_indicators=", BoolToText(InpUseCommonChartLineIndicators),
         ", ai_chart_line_suggestions=", BoolToText(InpEnableAIChartLineSuggestions),
         ", ai_chart_line_file=", InpAIChartLineSuggestionFile,
         ", ai_chart_line_context_file=", InpAIChartLineContextFile,
         ", ai_remove_omitted_chart_lines=", BoolToText(InpAIRemoveOmittedChartLines),
         ", ai_keep_omitted_same_direction_lines=", BoolToText(InpAIKeepOmittedSameDirectionLines),
         ", ai_keep_omitted_same_direction_seconds=", IntegerToString(InpAIKeepOmittedSameDirectionSeconds),
         ", ai_limit_fill_nudge_points=", IntegerToString(InpAILimitFillNudgePoints),
         ", ai_h4_screenshot_file=", InpAIH4ScreenshotFile,
         ", log_folder=", InpLogFolder,
         ", telegram=", BoolToText(InpTelegramEnabled),
         ", telegram_env=", (telegram_env == "" ? "-" : telegram_env),
         ", telegram_token=", (telegram_bot_token == "" ? "MISSING" : "SET"),
         ", telegram_chat_id=", (telegram_chat_id == "" ? "MISSING" : "SET"),
         ", pause_auto_modes_when_ai_enabled=", BoolToText(InpPauseAutoModesWhenAIChartLineSuggestionsEnabled),
         ", auto_create_chart_lines=", BoolToText(InpAutoCreateChartLines),
         ", effective_auto_create_chart_lines=", BoolToText(ShouldAutoCreateChartLines()),
         ", auto_create_both_directions=", BoolToText(InpAutoCreateBothDirections),
         ", auto_remove_inactive_direction=", BoolToText(InpAutoRemoveInactiveDirection),
         ", chart_line_require_h4_ema200_slope=", BoolToText(InpChartLineRequireH4EMA200Slope),
         ", chart_line_h4_ema200_slope_min_atr=", DoubleToString(InpChartLineH4EMA200SlopeMinATR, 3),
         ", max_chart_line_positions_per_mode=", IntegerToString(InpMaxChartLinePositionsPerMode),
         ", skip_fresh_auto_chart_line_orders=", BoolToText(InpSkipChartLineOrdersOnFreshAutoCreate),
         ", select_auto_created_chart_lines=", BoolToText(InpSelectAutoCreatedChartLines));
   Print("Risk guard settings: profit_floor_stop=", BoolToText(InpEnableProfitFloorStop),
         ", profit_floor_arm=", DoubleToString(InpProfitFloorArmMoney, 2),
         ", profit_floor_lock_money=", DoubleToString(InpProfitFloorLockMoney, 2),
         ", profit_floor_step_money=", DoubleToString(InpProfitFloorStepMoney, 2),
         ", profit_floor_remove_tp=", BoolToText(InpProfitFloorRemoveTakeProfit),
         ", max_loss_stop=", BoolToText(InpEnableMaxLossStop),
         ", max_loss_stop_points=", IntegerToString(InpMaxLossStopPoints),
         ", limit_magic=", IntegerToString((long)InpLimitMagicNumber),
         ", stop_magic=", IntegerToString((long)InpStopMagicNumber),
         ", stop_limit_magic=", IntegerToString((long)InpStopLimitMagicNumber),
         ", chart_line_magic=", IntegerToString((long)InpChartLineMagicNumber),
         ", model_direct_magic=", IntegerToString((long)InpModelDirectMagicNumber));
   Print("Model direct settings: enabled=", BoolToText(InpUseModelDirectTrading),
         ", recommendation_file=", InpModelRecommendationFile,
         ", use_top_rule=", BoolToText(InpModelDirectUseTopRule),
         ", min_samples=", IntegerToString(InpModelDirectMinSamples),
         ", min_score=", DoubleToString(InpModelDirectMinScore, 3),
         ", frequency_throttle=", BoolToText(InpModelUseFrequencyThrottle),
         ", low_frequency_cooldown_min=", IntegerToString(InpModelLowFrequencyCooldownMinutes),
         ", max_positions_per_direction=", IntegerToString(InpMaxModelDirectPositionsPerDirection),
         ", block_opposite_positions=", BoolToText(InpModelDirectBlockOppositePositions),
         ", cancel_managed_pending_orders=", BoolToText(InpModelDirectCancelManagedPendingOrders));
   Print("AI backtest replay: enabled=", BoolToText(InpEnableAIBacktestReplay),
         ", active=", BoolToText(ShouldUseAIBacktestReplay()),
         ", file=", InpAIBacktestReplayFile,
         ", use_common_files=", BoolToText(InpAIBacktestReplayUseCommonFiles),
         ", max_age_seconds=", IntegerToString(InpAIBacktestReplayMaxAgeSeconds));
   Print("Chart line names: ",
         InpBuyPullbackLineName, ", ",
         InpSellPullbackLineName, ", ",
         InpBuyBreakoutLineName, ", ",
         InpSellBreakdownLineName, ", ",
         InpBuyBreakoutTriggerLineName, "+", InpBuyRetestEntryLineName, ", ",
         InpSellBreakdownTriggerLineName, "+", InpSellRetestEntryLineName);
   if(InpUseCommonChartLineIndicators)
   {
      Print("Common chart-line indicator mode: EA reads only armed line names. ",
            "Lines ending with ", InpCommonIndicatorInactiveSuffix,
            " are ignored until they are dragged once.");
   }
   CleanupLegacyChartLineObjects();
   PrintTradingEnvironment();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   ReleaseAllIndicatorHandles();
}

bool IndicatorHandlesReady()
{
   return fast_ma_handle != INVALID_HANDLE &&
          slow_ma_handle != INVALID_HANDLE &&
          rsi_handle != INVALID_HANDLE &&
          atr_handle != INVALID_HANDLE &&
          chart_line_fast_ma_handle != INVALID_HANDLE &&
          chart_line_slow_ma_handle != INVALID_HANDLE &&
          chart_line_atr_handle != INVALID_HANDLE &&
          trend_slow_ma_handle != INVALID_HANDLE &&
          trend_baseline_ma_handle != INVALID_HANDLE &&
          trend_atr_handle != INVALID_HANDLE;
}

void ReleaseAllIndicatorHandles()
{
   ReleaseHandle(fast_ma_handle);
   ReleaseHandle(slow_ma_handle);
   ReleaseHandle(rsi_handle);
   ReleaseHandle(atr_handle);
   ReleaseHandle(chart_line_fast_ma_handle);
   ReleaseHandle(chart_line_slow_ma_handle);
   ReleaseHandle(chart_line_atr_handle);
   ReleaseHandle(trend_slow_ma_handle);
   ReleaseHandle(trend_baseline_ma_handle);
   ReleaseHandle(trend_atr_handle);
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.symbol != "" && trans.symbol != _Symbol)
      return;

   const ulong magic = ResolveTransactionMagic(trans, request);
   if(!IsManagedMagic(magic))
      return;

   Print("Managed trade transaction: type=", EnumToString(trans.type),
         ", magic=", IntegerToString((long)magic),
         ", order=", IntegerToString((long)trans.order),
         ", deal=", IntegerToString((long)trans.deal),
         ", order_type=", OrderTypeToText(trans.order_type),
         ", order_state=", EnumToString(trans.order_state),
         ", deal_type=", EnumToString(trans.deal_type),
         ", volume=", DoubleToString(trans.volume, VolumeDigits()),
         ", price=", DoubleToString(trans.price, _Digits),
         ", sl=", DoubleToString(trans.price_sl, _Digits),
         ", tp=", DoubleToString(trans.price_tp, _Digits),
         ", retcode=", IntegerToString((int)result.retcode),
         ", comment=", result.comment);

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal > 0)
   {
      LogManagedDealDetails(trans.deal);
      AppendDealLog(trans.deal);
      SendTelegramDealNotification(trans.deal);
   }
}

void OnTick()
{
   if(InpEnforceTargetSymbol && _Symbol != InpTargetSymbol)
   {
      if(!warned_symbol_mismatch)
      {
         Print("Skipping: EA target symbol is ", InpTargetSymbol, ", chart symbol is ", _Symbol);
         warned_symbol_mismatch = true;
      }
      return;
   }

   if(ManageMaxLossStops())
      return;

   if(ManageModelHoldTimeoutExits())
      return;

   if(ManageModelTrailingStops())
      return;

   if(ManageProfitFloorStops())
      return;

   if(IsSmallAccountGuardHit())
      return;

   if(!InpUseModelDirectTrading)
   {
      LogVerbose("Skipping: pure model EA requires model direct trading to be enabled.");
      return;
   }

   if(InpModelDirectCancelManagedPendingOrders)
      RemoveAllManagedPendingOrders();

   TrySubmitModelDirectEntry();
}

bool ValidateInputs()
{
   if(InpFastMAPeriod <= 0 || InpSlowMAPeriod <= 0 || InpTrendBaselineMAPeriod <= 0 ||
      InpRSIPeriod <= 0 || InpATRPeriod <= 0)
   {
      Print("Invalid indicator period input.");
      return false;
   }

   if(PeriodSeconds(InpSignalTimeframe) <= 0 ||
      PeriodSeconds(InpTrendTimeframe) <= 0 ||
      PeriodSeconds(InpChartLineTimeframe) <= 0)
   {
      Print("Invalid timeframe input.");
      return false;
   }

   if(InpFastMAPeriod >= InpSlowMAPeriod)
   {
      Print("Invalid MA periods: fast EMA must be lower than slow EMA.");
      return false;
   }

   if(InpBreakoutLookbackBars < 2 || InpTrendConfirmBars < 1 || InpOrderExpiryBars < 1)
   {
      Print("Invalid lookback/confirmation/expiry input.");
      return false;
   }

   if(InpChartLineCheckSeconds < 1 ||
      InpChartLineLabelBarsBack < 0 ||
      InpMaxChartLinePendingOrders < 1 ||
      InpChartLineExpiryBars < 1 ||
      InpAIChartLineCheckSeconds < 1 ||
      InpAIChartLineSuggestionMaxAgeSeconds < 1 ||
      (InpAIKeepOmittedSameDirectionLines && InpAIKeepOmittedSameDirectionSeconds < 1) ||
      InpAILimitFillNudgePoints < 0 ||
      (InpEnableAIBacktestReplay &&
       (InpAIBacktestReplayFile == "" || InpAIBacktestReplayMaxAgeSeconds < 1)) ||
      (InpEnableAIChartLineSuggestions && InpAIChartLineSuggestionFile == "") ||
      (InpExportAIChartLineContext &&
       (InpAIChartLineContextFile == "" || InpAIChartLineContextExportSeconds < 1)) ||
      (InpExportAIH4Screenshot &&
       (InpAIH4ScreenshotFile == "" ||
        InpAIH4ScreenshotWidth < 320 ||
        InpAIH4ScreenshotHeight < 240 ||
        InpAIH4ScreenshotExportSeconds < 1 ||
        PeriodSeconds(InpAIH4ScreenshotTimeframe) <= 0)) ||
      InpAIH4EMA200SlopeMinATR < 0.0 ||
      (InpUseCommonChartLineIndicators && InpCommonIndicatorInactiveSuffix == ""))
   {
      Print("Invalid chart line trading input.");
      return false;
   }

   if(ShouldAutoCreateChartLines() && !InpEnableChartLineTrading)
   {
      Print("Auto chart-line creation requires chart-line trading to be enabled.");
      return false;
   }

   if(InpRiskPerOrderPercent <= 0.0 ||
      InpMaxVolumePerTrade < 0.0 ||
      InpMinEquityToTrade < 0.0 ||
      InpMaxDailyLossMoney < 0.0 ||
      InpMaxConsecutiveLosses < 0 ||
      InpStopLossATR <= 0.0 || InpTakeProfitRewardRisk <= 0.0 ||
      InpProfitFloorArmMoney <= 0.0 || InpProfitFloorLockMoney < 0.0 ||
      InpProfitFloorLockMoney >= InpProfitFloorArmMoney ||
      InpProfitFloorStepMoney <= 0.0 ||
      InpMaxLossStopPoints < 1)
   {
      Print("Invalid risk input.");
      return false;
   }

   if(InpCalendarPreEventMinutes < 0 || InpCalendarPostEventMinutes < 0 ||
      InpCalendarCachePrefix == "" ||
      InpCalendarCacheMaxAgeSeconds < 1 ||
      InpCalendarCacheMaxEvents < 1)
   {
      Print("Invalid calendar cache input.");
      return false;
   }

   if(InpMaxManagedPendingOrders < 1 || InpMaxPendingOrdersPerMode < 1)
   {
      Print("Invalid pending order limit input.");
      return false;
   }

   if(InpUseModelDirectTrading &&
      (InpModelRecommendationFile == "" ||
       InpModelMaxAgeSeconds < 1 ||
       InpModelDirectMinSamples < 0 ||
       InpModelDirectMinScore < 0.0 ||
       InpMaxModelDirectPositionsPerDirection < 1 ||
       InpMaxCombinedBTCPositions < 1 ||
       InpMaxCombinedBTCVolume < 0.0 ||
       InpModelLowFrequencyCooldownMinutes < 0 ||
       InpModelNormalFrequencyCooldownMinutes < 0 ||
       InpModelHighFrequencyCooldownMinutes < 0))
   {
      Print("Invalid model direct trading input.");
      return false;
   }

   if(InpMaxChartLinePositionsPerMode < 1)
   {
      Print("Invalid chart-line position limit input.");
      return false;
   }

   if(InpLimitMagicNumber == InpStopMagicNumber ||
      InpLimitMagicNumber == InpStopLimitMagicNumber ||
      InpLimitMagicNumber == InpChartLineMagicNumber ||
      InpLimitMagicNumber == InpModelDirectMagicNumber ||
      InpStopMagicNumber == InpStopLimitMagicNumber ||
      InpStopMagicNumber == InpChartLineMagicNumber ||
      InpStopMagicNumber == InpModelDirectMagicNumber ||
      InpStopLimitMagicNumber == InpChartLineMagicNumber ||
      InpStopLimitMagicNumber == InpModelDirectMagicNumber ||
      InpChartLineMagicNumber == InpModelDirectMagicNumber)
   {
      Print("Magic numbers must be unique.");
      return false;
   }

   return true;
}

int ManualIndicatorWarmupBars(const int bars_needed, const int max_period)
{
   return MathMax(bars_needed + max_period * 4 + 20, bars_needed + 80);
}

bool BuildAggregatedManualRates(const ENUM_TIMEFRAMES timeframe,
                                const int copy_count,
                                const int bars_needed,
                                MqlRates &raw_rates[],
                                MqlRates &rates[])
{
   const int source_seconds = PeriodSeconds(InpSignalTimeframe);
   const int target_seconds = PeriodSeconds(timeframe);
   if(source_seconds <= 0 ||
      target_seconds <= source_seconds ||
      target_seconds % source_seconds != 0)
      return false;

   const int ratio = target_seconds / source_seconds;
   MqlRates source_rates[];
   ArraySetAsSeries(source_rates, true);

   ResetLastError();
   const int source_needed = copy_count * ratio + ratio * 2;
   const int source_copied = CopyRates(_Symbol, InpSignalTimeframe, 0, source_needed, source_rates);
   if(source_copied < bars_needed * ratio)
      return false;

   MqlRates aggregated[];
   MqlRates current;
   ZeroMemory(current);
   bool has_bucket = false;
   datetime current_bucket_time = 0;

   for(int i = source_copied - 1; i >= 0; i--)
   {
      const datetime bucket_time = (datetime)(((long)source_rates[i].time / target_seconds) * target_seconds);
      if(!has_bucket || bucket_time != current_bucket_time)
      {
         if(has_bucket)
         {
            const int index = ArraySize(aggregated);
            ArrayResize(aggregated, index + 1);
            aggregated[index] = current;
         }

         current = source_rates[i];
         current.time = bucket_time;
         current_bucket_time = bucket_time;
         has_bucket = true;
      }
      else
      {
         current.high = MathMax(current.high, source_rates[i].high);
         current.low = MathMin(current.low, source_rates[i].low);
         current.close = source_rates[i].close;
         current.tick_volume += source_rates[i].tick_volume;
         current.real_volume += source_rates[i].real_volume;
         current.spread = source_rates[i].spread;
      }
   }

   if(has_bucket)
   {
      const int index = ArraySize(aggregated);
      ArrayResize(aggregated, index + 1);
      aggregated[index] = current;
   }

   const int aggregated_count = ArraySize(aggregated);
   if(aggregated_count < bars_needed)
      return false;

   const int output_count = MathMin(aggregated_count, copy_count);
   ArrayResize(raw_rates, output_count);
   ArraySetAsSeries(raw_rates, true);
   for(int i = 0; i < output_count; i++)
      raw_rates[i] = aggregated[aggregated_count - 1 - i];

   ArrayResize(rates, bars_needed);
   ArraySetAsSeries(rates, true);
   for(int i = 0; i < bars_needed; i++)
      rates[i] = raw_rates[i];

   return true;
}

bool CopyManualIndicatorRates(const ENUM_TIMEFRAMES timeframe,
                              const int bars_needed,
                              const int max_period,
                              MqlRates &raw_rates[],
                              MqlRates &rates[])
{
   const int copy_count = ManualIndicatorWarmupBars(bars_needed, max_period);

   ArraySetAsSeries(raw_rates, true);
   ArraySetAsSeries(rates, true);

   if((bool)MQLInfoInteger(MQL_TESTER) &&
      timeframe != InpSignalTimeframe &&
      BuildAggregatedManualRates(timeframe, copy_count, bars_needed, raw_rates, rates))
      return true;

   ResetLastError();
   const int copied = CopyRates(_Symbol, timeframe, 0, copy_count, raw_rates);
   if(copied < bars_needed)
   {
      const int direct_error = GetLastError();
      if(BuildAggregatedManualRates(timeframe, copy_count, bars_needed, raw_rates, rates))
         return true;

      Print("Skipping: not enough manual indicator rates. timeframe=",
            EnumToString(timeframe),
            ", copied=", IntegerToString(copied),
            ", needed=", IntegerToString(bars_needed),
            ", error=", IntegerToString(direct_error));
      return false;
   }

   ArrayResize(rates, bars_needed);
   ArraySetAsSeries(rates, true);
   for(int i = 0; i < bars_needed; i++)
      rates[i] = raw_rates[i];

   return true;
}

void CopyManualValues(const double &source[],
                      const int bars_needed,
                      double &target[])
{
   ArrayResize(target, bars_needed);
   ArraySetAsSeries(target, true);
   for(int i = 0; i < bars_needed; i++)
      target[i] = source[i];
}

void CalculateManualEMA(const MqlRates &rates[],
                        const int count,
                        const int period,
                        double &values[])
{
   ArrayResize(values, count);
   ArraySetAsSeries(values, true);
   if(count <= 0)
      return;

   const double alpha = 2.0 / ((double)period + 1.0);
   values[count - 1] = rates[count - 1].close;
   for(int i = count - 2; i >= 0; i--)
      values[i] = alpha * rates[i].close + (1.0 - alpha) * values[i + 1];
}

double ManualTrueRange(const MqlRates &rates[],
                       const int index,
                       const int count)
{
   const double previous_close = (index + 1 < count)
                                 ? rates[index + 1].close
                                 : rates[index].close;
   const double high_low = rates[index].high - rates[index].low;
   const double high_close = MathAbs(rates[index].high - previous_close);
   const double low_close = MathAbs(rates[index].low - previous_close);
   return MathMax(high_low, MathMax(high_close, low_close));
}

void CalculateManualATR(const MqlRates &rates[],
                        const int count,
                        const int period,
                        double &values[])
{
   ArrayResize(values, count);
   ArraySetAsSeries(values, true);
   if(count <= 0)
      return;

   values[count - 1] = ManualTrueRange(rates, count - 1, count);
   for(int i = count - 2; i >= 0; i--)
   {
      const double true_range = ManualTrueRange(rates, i, count);
      if(period <= 1)
         values[i] = true_range;
      else
         values[i] = (values[i + 1] * ((double)period - 1.0) + true_range) / (double)period;
   }
}

void CalculateManualRSI(const MqlRates &rates[],
                        const int count,
                        const int period,
                        double &values[])
{
   ArrayResize(values, count);
   ArraySetAsSeries(values, true);
   if(count <= 0)
      return;

   double avg_gain = 0.0;
   double avg_loss = 0.0;
   values[count - 1] = 50.0;

   for(int i = count - 2; i >= 0; i--)
   {
      const double change = rates[i].close - rates[i + 1].close;
      const double gain = MathMax(change, 0.0);
      const double loss = MathMax(-change, 0.0);

      if(i == count - 2 || period <= 1)
      {
         avg_gain = gain;
         avg_loss = loss;
      }
      else
      {
         avg_gain = (avg_gain * ((double)period - 1.0) + gain) / (double)period;
         avg_loss = (avg_loss * ((double)period - 1.0) + loss) / (double)period;
      }

      if(avg_loss <= 0.0)
         values[i] = avg_gain <= 0.0 ? 50.0 : 100.0;
      else
      {
         const double rs = avg_gain / avg_loss;
         values[i] = 100.0 - (100.0 / (1.0 + rs));
      }
   }
}

bool LoadManualSignalData(double &fast_ma[],
                          double &slow_ma[],
                          double &rsi_values[],
                          double &atr_values[],
                          MqlRates &rates[])
{
   const int bars_needed = MathMax(InpBreakoutLookbackBars + 4, 12);
   const int max_period = MathMax(MathMax(InpFastMAPeriod, InpSlowMAPeriod),
                                  MathMax(InpRSIPeriod, InpATRPeriod));
   MqlRates raw_rates[];
   if(!CopyManualIndicatorRates(InpSignalTimeframe, bars_needed, max_period, raw_rates, rates))
      return false;

   double manual_fast_ma[];
   double manual_slow_ma[];
   double manual_rsi[];
   double manual_atr[];
   const int count = ArraySize(raw_rates);
   CalculateManualEMA(raw_rates, count, InpFastMAPeriod, manual_fast_ma);
   CalculateManualEMA(raw_rates, count, InpSlowMAPeriod, manual_slow_ma);
   CalculateManualRSI(raw_rates, count, InpRSIPeriod, manual_rsi);
   CalculateManualATR(raw_rates, count, InpATRPeriod, manual_atr);

   CopyManualValues(manual_fast_ma, bars_needed, fast_ma);
   CopyManualValues(manual_slow_ma, bars_needed, slow_ma);
   CopyManualValues(manual_rsi, bars_needed, rsi_values);
   CopyManualValues(manual_atr, bars_needed, atr_values);
   return true;
}

bool LoadManualChartLineData(double &fast_ma[],
                             double &slow_ma[],
                             double &atr_values[],
                             MqlRates &rates[])
{
   const int bars_needed = MathMax(InpBreakoutLookbackBars + 4, 12);
   const int max_period = MathMax(MathMax(InpFastMAPeriod, InpSlowMAPeriod), InpATRPeriod);
   MqlRates raw_rates[];
   if(!CopyManualIndicatorRates(InpChartLineTimeframe, bars_needed, max_period, raw_rates, rates))
      return false;

   double manual_fast_ma[];
   double manual_slow_ma[];
   double manual_atr[];
   const int count = ArraySize(raw_rates);
   CalculateManualEMA(raw_rates, count, InpFastMAPeriod, manual_fast_ma);
   CalculateManualEMA(raw_rates, count, InpSlowMAPeriod, manual_slow_ma);
   CalculateManualATR(raw_rates, count, InpATRPeriod, manual_atr);

   CopyManualValues(manual_fast_ma, bars_needed, fast_ma);
   CopyManualValues(manual_slow_ma, bars_needed, slow_ma);
   CopyManualValues(manual_atr, bars_needed, atr_values);
   return true;
}

bool LoadManualTrendData(const int bars_needed,
                         double &trend_slow_ma[],
                         double &trend_baseline_ma[],
                         double &trend_atr[],
                         MqlRates &trend_rates[])
{
   const int max_period = MathMax(MathMax(InpSlowMAPeriod, InpTrendBaselineMAPeriod), InpATRPeriod);
   MqlRates raw_rates[];
   if(!CopyManualIndicatorRates(InpTrendTimeframe, bars_needed, max_period, raw_rates, trend_rates))
      return false;

   double manual_slow_ma[];
   double manual_baseline_ma[];
   double manual_atr[];
   const int count = ArraySize(raw_rates);
   CalculateManualEMA(raw_rates, count, InpSlowMAPeriod, manual_slow_ma);
   CalculateManualEMA(raw_rates, count, InpTrendBaselineMAPeriod, manual_baseline_ma);
   CalculateManualATR(raw_rates, count, InpATRPeriod, manual_atr);

   CopyManualValues(manual_slow_ma, bars_needed, trend_slow_ma);
   CopyManualValues(manual_baseline_ma, bars_needed, trend_baseline_ma);
   CopyManualValues(manual_atr, bars_needed, trend_atr);
   return true;
}

bool LoadSignalData(double &fast_ma[],
                    double &slow_ma[],
                    double &rsi_values[],
                    double &atr_values[],
                    MqlRates &rates[])
{
   if(use_manual_indicator_values)
      return LoadManualSignalData(fast_ma, slow_ma, rsi_values, atr_values, rates);

   const int bars_needed = MathMax(InpBreakoutLookbackBars + 4, 12);

   ArraySetAsSeries(fast_ma, true);
   ArraySetAsSeries(slow_ma, true);
   ArraySetAsSeries(rsi_values, true);
   ArraySetAsSeries(atr_values, true);
   ArraySetAsSeries(rates, true);

   if(CopyBuffer(fast_ma_handle, 0, 0, bars_needed, fast_ma) < bars_needed ||
      CopyBuffer(slow_ma_handle, 0, 0, bars_needed, slow_ma) < bars_needed ||
      CopyBuffer(rsi_handle, 0, 0, bars_needed, rsi_values) < bars_needed ||
      CopyBuffer(atr_handle, 0, 0, bars_needed, atr_values) < bars_needed ||
      CopyRates(_Symbol, InpSignalTimeframe, 0, bars_needed, rates) < bars_needed)
   {
      Print("Skipping: not enough signal data. error=", GetLastError());
      return false;
   }

   return true;
}

bool LoadChartLineData(double &fast_ma[],
                       double &slow_ma[],
                       double &atr_values[],
                       MqlRates &rates[])
{
   if(use_manual_indicator_values)
      return LoadManualChartLineData(fast_ma, slow_ma, atr_values, rates);

   const int bars_needed = MathMax(InpBreakoutLookbackBars + 4, 12);

   ArraySetAsSeries(fast_ma, true);
   ArraySetAsSeries(slow_ma, true);
   ArraySetAsSeries(atr_values, true);
   ArraySetAsSeries(rates, true);

   if(CopyBuffer(chart_line_fast_ma_handle, 0, 0, bars_needed, fast_ma) < bars_needed ||
      CopyBuffer(chart_line_slow_ma_handle, 0, 0, bars_needed, slow_ma) < bars_needed ||
      CopyBuffer(chart_line_atr_handle, 0, 0, bars_needed, atr_values) < bars_needed ||
      CopyRates(_Symbol, InpChartLineTimeframe, 0, bars_needed, rates) < bars_needed)
   {
      Print("Skipping: not enough chart-line data. timeframe=",
            EnumToString(InpChartLineTimeframe),
            ", error=", GetLastError());
      return false;
   }

   return true;
}

TradeSignal GetHigherTimeframeBias()
{
   const int bars_needed = InpTrendConfirmBars + 3;
   double trend_slow_ma[];
   double trend_baseline_ma[];
   double trend_atr[];
   MqlRates trend_rates[];

   ArraySetAsSeries(trend_slow_ma, true);
   ArraySetAsSeries(trend_baseline_ma, true);
   ArraySetAsSeries(trend_atr, true);
   ArraySetAsSeries(trend_rates, true);

   bool trend_data_loaded = false;
   if(use_manual_indicator_values)
      trend_data_loaded = LoadManualTrendData(bars_needed, trend_slow_ma, trend_baseline_ma, trend_atr, trend_rates);
   else
   {
      trend_data_loaded = CopyBuffer(trend_slow_ma_handle, 0, 0, bars_needed, trend_slow_ma) >= bars_needed &&
                          CopyBuffer(trend_baseline_ma_handle, 0, 0, bars_needed, trend_baseline_ma) >= bars_needed &&
                          CopyBuffer(trend_atr_handle, 0, 0, bars_needed, trend_atr) >= bars_needed &&
                          CopyRates(_Symbol, InpTrendTimeframe, 0, bars_needed, trend_rates) >= bars_needed;
   }

   if(!trend_data_loaded)
   {
      Print("Skipping: not enough trend data. error=", GetLastError());
      return SIGNAL_NONE;
   }

   bool bullish = true;
   bool bearish = true;
   for(int i = 1; i <= InpTrendConfirmBars; i++)
   {
      const double trend_gap = MathAbs(trend_slow_ma[i] - trend_baseline_ma[i]);
      const double min_gap = trend_atr[i] * InpMinTrendSpreadATR;
      bullish = bullish && trend_rates[i].close > trend_slow_ma[i] &&
                trend_slow_ma[i] > trend_baseline_ma[i] &&
                trend_gap >= min_gap;
      bearish = bearish && trend_rates[i].close < trend_slow_ma[i] &&
                trend_slow_ma[i] < trend_baseline_ma[i] &&
                trend_gap >= min_gap;
   }

   if(bullish)
      return SIGNAL_BUY;
   if(bearish)
      return SIGNAL_SELL;
   return SIGNAL_NONE;
}

double H4EMA200SlopeThreshold(const double atr, const double min_slope_atr)
{
   if(atr <= 0.0)
      return _Point;
   return MathMax(atr * min_slope_atr, _Point);
}

TradeSignal TrendSideFromSlope(const double slope, const double min_slope)
{
   if(slope >= min_slope)
      return SIGNAL_BUY;
   if(slope <= -min_slope)
      return SIGNAL_SELL;
   return SIGNAL_NONE;
}

TradeSignal GetH4EMA200TrendSide(const double min_slope_atr)
{
   const int bars_needed = 3;
   double trend_baseline_ma[];
   double trend_atr[];

   ArraySetAsSeries(trend_baseline_ma, true);
   ArraySetAsSeries(trend_atr, true);

   bool trend_data_loaded = false;
   if(use_manual_indicator_values)
   {
      double unused_slow_ma[];
      MqlRates unused_rates[];
      trend_data_loaded = LoadManualTrendData(bars_needed,
                                              unused_slow_ma,
                                              trend_baseline_ma,
                                              trend_atr,
                                              unused_rates);
   }
   else
   {
      trend_data_loaded = CopyBuffer(trend_baseline_ma_handle, 0, 0, bars_needed, trend_baseline_ma) >= bars_needed &&
                          CopyBuffer(trend_atr_handle, 0, 0, bars_needed, trend_atr) >= bars_needed;
   }

   if(!trend_data_loaded)
      return SIGNAL_NONE;

   const double ema200_slope = trend_baseline_ma[1] - trend_baseline_ma[2];
   const double min_slope = H4EMA200SlopeThreshold(trend_atr[1], min_slope_atr);
   return TrendSideFromSlope(ema200_slope, min_slope);
}

string H4EMA200DirectionText(const TradeSignal signal)
{
   if(signal == SIGNAL_BUY)
      return "UP";
   if(signal == SIGNAL_SELL)
      return "DOWN";
   return "NONE";
}

bool IsTrendTooWeak(const double &fast_ma[], const double &slow_ma[], const double atr)
{
   const double spread = MathAbs(fast_ma[1] - slow_ma[1]);
   const double slow_slope = MathAbs(slow_ma[1] - slow_ma[3]);
   return spread < atr * InpMinTrendSpreadATR ||
          slow_slope < atr * InpMinSlowMASlopeATR;
}

bool IsTradeSetupAllowed(const double atr)
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      LogVerbose("Terminal auto trading is disabled.");
      if(!InpDryRun)
         return false;
   }

   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      LogVerbose("Account trading is disabled.");
      if(!InpDryRun)
         return false;
   }

   if(!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE))
   {
      Print("Skipping: symbol trade mode is disabled.");
      return false;
   }

   const int spread_points = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   const double spread_price = spread_points * _Point;
   if(spread_points > InpMaxSpreadPoints || spread_price > atr * InpMaxSpreadATR)
   {
      LogVerbose("Skipping: spread too wide. points=" + IntegerToString(spread_points) +
                 ", spread_price=" + DoubleToString(spread_price, _Digits) +
                 ", atr=" + DoubleToString(atr, _Digits));
      return false;
   }

   if(IsEconomicCalendarRiskActive())
      return false;

   return true;
}

bool IsEconomicCalendarRiskActive()
{
   if(!InpUseEconomicCalendarFilter)
      return false;

   const datetime now_time = TimeCurrent();

   double service_running = 0.0;
   if(!ReadCalendarCacheValue("service_running", service_running) || service_running < 0.5)
   {
      Print("Economic calendar cache service is not running or not initialized.");
      return InpBlockOnCalendarError;
   }

   double updating = 0.0;
   if(ReadCalendarCacheValue("updating", updating) && updating > 0.5)
      return InpBlockOnCalendarError;

   double cache_error = 0.0;
   if(ReadCalendarCacheValue("error", cache_error) && cache_error > 0.5)
   {
      Print("Economic calendar cache service reported an error.");
      return InpBlockOnCalendarError;
   }

   double updated_at_value = 0.0;
   if(!ReadCalendarCacheValue("updated_at", updated_at_value))
      return InpBlockOnCalendarError;

   const datetime updated_at = (datetime)updated_at_value;
   if(updated_at <= 0 || now_time - updated_at > InpCalendarCacheMaxAgeSeconds)
   {
      Print("Economic calendar cache is stale. updated_at=",
            TimeToString(updated_at, TIME_DATE | TIME_SECONDS));
      return InpBlockOnCalendarError;
   }

   double count_value = 0.0;
   if(!ReadCalendarCacheValue("count", count_value))
      return InpBlockOnCalendarError;

   int event_count = (int)count_value;
   if(event_count > InpCalendarCacheMaxEvents)
      event_count = InpCalendarCacheMaxEvents;

   for(int i = 0; i < event_count; ++i)
   {
      double event_time_value = 0.0;
      if(!ReadCalendarCacheEventTime(i, event_time_value))
         continue;

      const datetime event_time = (datetime)event_time_value;
      const datetime risk_start_time = event_time - (datetime)(InpCalendarPreEventMinutes * 60);
      const datetime risk_end_time = event_time + (datetime)(InpCalendarPostEventMinutes * 60);
      if(now_time < risk_start_time || now_time > risk_end_time)
         continue;

      LogVerbose("Economic calendar risk: " +
                 InpCalendarCachePrefix +
                 " event at " +
                 TimeToString(event_time, TIME_DATE | TIME_MINUTES));
      return true;
   }

   return false;
}

bool ReadCalendarCacheValue(const string field, double &value)
{
   const string key = CalendarCacheKey(field);
   if(!GlobalVariableCheck(key))
      return false;

   value = GlobalVariableGet(key);
   return true;
}

bool ReadCalendarCacheEventTime(const int index, double &value)
{
   const string key = InpCalendarCachePrefix + ".event." + IntegerToString(index) + ".time";
   if(!GlobalVariableCheck(key))
      return false;

   value = GlobalVariableGet(key);
   return true;
}

string CalendarCacheKey(const string field)
{
   return InpCalendarCachePrefix + "." + field;
}

bool HasChartLineObjects()
{
   return CountChartLineObjects() > 0;
}

bool ShouldAutoCreateChartLines()
{
   return InpAutoCreateChartLines && !InpUseCommonChartLineIndicators;
}

int CountChartLineObjects()
{
   int count = 0;
   if(ChartLineObjectExists(InpBuyPullbackLineName))
      count++;
   if(ChartLineObjectExists(InpSellPullbackLineName))
      count++;
   if(ChartLineObjectExists(InpBuyBreakoutLineName))
      count++;
   if(ChartLineObjectExists(InpSellBreakdownLineName))
      count++;
   if(ChartLineObjectExists(InpBuyBreakoutTriggerLineName))
      count++;
   if(ChartLineObjectExists(InpBuyRetestEntryLineName))
      count++;
   if(ChartLineObjectExists(InpSellBreakdownTriggerLineName))
      count++;
   if(ChartLineObjectExists(InpSellRetestEntryLineName))
      count++;
   return count;
}

bool ChartLineObjectExists(const string object_name)
{
   return object_name != "" && ObjectFind(0, object_name) >= 0;
}

void TryExportAIChartLineContext()
{
   const datetime now_time = TimeCurrent();
   if(last_ai_chart_line_context_export_time > 0 &&
      now_time - last_ai_chart_line_context_export_time < InpAIChartLineContextExportSeconds)
      return;

   last_ai_chart_line_context_export_time = now_time;
   TryExportAIH4Screenshot(now_time);

   double fast_ma[];
   double slow_ma[];
   double atr_values[];
   MqlRates rates[];
   if(!LoadChartLineData(fast_ma, slow_ma, atr_values, rates))
      return;

   if(atr_values[1] <= 0.0)
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   double breakout_high = 0.0;
   double breakout_low = 0.0;
   GetBreakoutRange(rates, breakout_high, breakout_low);

   const double atr = atr_values[1];
   const double buy_pullback = NormalizePrice(MathMin(fast_ma[1], slow_ma[1]) -
                                              atr * InpLimitOffsetATR);
   const double sell_pullback = NormalizePrice(MathMax(fast_ma[1], slow_ma[1]) +
                                               atr * InpLimitOffsetATR);
   const double buy_breakout = NormalizePrice(breakout_high + atr * InpStopEntryOffsetATR);
   const double sell_breakdown = NormalizePrice(breakout_low - atr * InpStopEntryOffsetATR);
   const double buy_retest_entry = NormalizePrice(buy_breakout -
                                                  atr * InpStopLimitRetestATR);
   const double sell_retest_entry = NormalizePrice(sell_breakdown +
                                                   atr * InpStopLimitRetestATR);

   const TradeSignal h4_bias = GetHigherTimeframeBias();
   const string json = BuildAIChartLineContextJson(now_time,
                                                   tick,
                                                   fast_ma[1],
                                                   slow_ma[1],
                                                   atr,
                                                   rates[1],
                                                   breakout_high,
                                                   breakout_low,
                                                   buy_pullback,
                                                   sell_pullback,
                                                   buy_breakout,
                                                   sell_breakdown,
                                                   buy_retest_entry,
                                                   sell_retest_entry,
                                                   h4_bias);

   int open_flags = FILE_WRITE | FILE_TXT | FILE_ANSI;
   if(InpAIChartLineUseCommonFiles)
      open_flags |= FILE_COMMON;

   ResetLastError();
   const int file_handle = FileOpen(InpAIChartLineContextFile, open_flags);
   if(file_handle == INVALID_HANDLE)
   {
      Print("Failed to open AI chart-line context file. file=",
            InpAIChartLineContextFile,
            ", error=", GetLastError());
      return;
   }

   FileWriteString(file_handle, json);
   FileClose(file_handle);
}

string BuildAIChartLineContextJson(const datetime now_time,
                                   const MqlTick &tick,
                                   const double fast_ma,
                                   const double slow_ma,
                                   const double atr,
                                   const MqlRates &last_closed_bar,
                                   const double breakout_high,
                                   const double breakout_low,
                                   const double buy_pullback,
                                   const double sell_pullback,
                                   const double buy_breakout,
                                   const double sell_breakdown,
                                   const double buy_retest_entry,
                                   const double sell_retest_entry,
                                   const TradeSignal h4_bias)
{
   string json = "{\n";
   json += "  \"symbol\": \"" + _Symbol + "\",\n";
   json += "  \"server_time\": " + IntegerToString((long)now_time) + ",\n";
   json += "  \"server_time_text\": \"" + TimeToString(now_time, TIME_DATE | TIME_SECONDS) + "\",\n";
   json += "  \"source\": \"CodexPendingOrderEA_BTCUSD\",\n";
   json += "  \"bid\": " + JsonPrice(tick.bid) + ",\n";
   json += "  \"ask\": " + JsonPrice(tick.ask) + ",\n";
   json += "  \"last\": " + JsonPrice(tick.last) + ",\n";
   json += "  \"spread_points\": " + IntegerToString((long)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)) + ",\n";
   json += "  \"signal_timeframe\": \"" + EnumToString(InpSignalTimeframe) + "\",\n";
   json += "  \"trade_cycle_minutes\": " + IntegerToString(MathMax(PeriodSeconds(InpSignalTimeframe) / 60, 1)) + ",\n";
   json += "  \"trend_timeframe\": \"" + EnumToString(InpTrendTimeframe) + "\",\n";
   json += "  \"h4_bias\": \"" + TradeSignalToText(h4_bias) + "\",\n";
   json += BuildH4TrendContextJson();
   json += "  \"h4_screenshot_file\": \"" + InpAIH4ScreenshotFile + "\",\n";
   json += "  \"h4_screenshot_timeframe\": \"" + EnumToString(InpAIH4ScreenshotTimeframe) + "\",\n";
   json += "  \"chart_line_timeframe\": \"" + EnumToString(InpChartLineTimeframe) + "\",\n";
   json += "  \"d1_ema_fast\": " + JsonPrice(fast_ma) + ",\n";
   json += "  \"d1_ema_slow\": " + JsonPrice(slow_ma) + ",\n";
   json += "  \"d1_atr\": " + JsonPrice(atr) + ",\n";
   json += "  \"d1_last_closed\": {\n";
   json += "    \"time\": " + IntegerToString((long)last_closed_bar.time) + ",\n";
   json += "    \"open\": " + JsonPrice(last_closed_bar.open) + ",\n";
   json += "    \"high\": " + JsonPrice(last_closed_bar.high) + ",\n";
   json += "    \"low\": " + JsonPrice(last_closed_bar.low) + ",\n";
   json += "    \"close\": " + JsonPrice(last_closed_bar.close) + "\n";
   json += "  },\n";
   json += "  \"breakout_range\": {\n";
   json += "    \"lookback_bars\": " + IntegerToString(InpBreakoutLookbackBars) + ",\n";
   json += "    \"high\": " + JsonPrice(breakout_high) + ",\n";
   json += "    \"low\": " + JsonPrice(breakout_low) + "\n";
   json += "  },\n";
   json += "  \"ea_reference_lines\": {\n";
   json += "    \"BUY_PULLBACK\": " + JsonPrice(buy_pullback) + ",\n";
   json += "    \"BUY_BREAKOUT\": " + JsonPrice(buy_breakout) + ",\n";
   json += "    \"BUY_BREAKOUT_TRIGGER\": " + JsonPrice(buy_breakout) + ",\n";
   json += "    \"BUY_RETEST_ENTRY\": " + JsonPrice(buy_retest_entry) + ",\n";
   json += "    \"SELL_PULLBACK\": " + JsonPrice(sell_pullback) + ",\n";
   json += "    \"SELL_BREAKDOWN\": " + JsonPrice(sell_breakdown) + ",\n";
   json += "    \"SELL_BREAKDOWN_TRIGGER\": " + JsonPrice(sell_breakdown) + ",\n";
   json += "    \"SELL_RETEST_ENTRY\": " + JsonPrice(sell_retest_entry) + "\n";
   json += "  }\n";
   json += "}\n";
   return json;
}

string BuildH4TrendContextJson()
{
   const int bars_needed = 3;
   double trend_slow_ma[];
   double trend_baseline_ma[];
   double trend_atr[];
   MqlRates trend_rates[];

   ArraySetAsSeries(trend_slow_ma, true);
   ArraySetAsSeries(trend_baseline_ma, true);
   ArraySetAsSeries(trend_atr, true);
   ArraySetAsSeries(trend_rates, true);

   bool trend_data_loaded = false;
   if(use_manual_indicator_values)
      trend_data_loaded = LoadManualTrendData(bars_needed, trend_slow_ma, trend_baseline_ma, trend_atr, trend_rates);
   else
   {
      trend_data_loaded = CopyBuffer(trend_slow_ma_handle, 0, 0, bars_needed, trend_slow_ma) >= bars_needed &&
                          CopyBuffer(trend_baseline_ma_handle, 0, 0, bars_needed, trend_baseline_ma) >= bars_needed &&
                          CopyBuffer(trend_atr_handle, 0, 0, bars_needed, trend_atr) >= bars_needed &&
                          CopyRates(_Symbol, InpTrendTimeframe, 0, bars_needed, trend_rates) >= bars_needed;
   }

   if(!trend_data_loaded)
   {
      return "  \"h4_ema200_direction\": \"UNKNOWN\",\n"
             "  \"h4_ema200_slope_threshold\": 0,\n"
             "  \"h4_trend\": {\"available\": false},\n";
   }

   const double ema200_slope = trend_baseline_ma[1] - trend_baseline_ma[2];
   const double ema50_slope = trend_slow_ma[1] - trend_slow_ma[2];
   const double ema200_slope_threshold = H4EMA200SlopeThreshold(trend_atr[1], InpChartLineH4EMA200SlopeMinATR);
   const TradeSignal ema200_side = TrendSideFromSlope(ema200_slope, ema200_slope_threshold);
   const string ema200_direction = H4EMA200DirectionText(ema200_side);

   string ema50_direction = "FLAT";
   if(ema50_slope > _Point)
      ema50_direction = "UP";
   else if(ema50_slope < -_Point)
      ema50_direction = "DOWN";

   string json = "  \"h4_ema200_direction\": \"" + ema200_direction + "\",\n";
   json += "  \"h4_ema200_slope_threshold\": " + JsonPrice(ema200_slope_threshold) + ",\n";
   json += "  \"h4_trend\": {\n";
   json += "    \"available\": true,\n";
   json += "    \"last_closed_time\": " + IntegerToString((long)trend_rates[1].time) + ",\n";
   json += "    \"last_closed_close\": " + JsonPrice(trend_rates[1].close) + ",\n";
   json += "    \"ema50\": " + JsonPrice(trend_slow_ma[1]) + ",\n";
   json += "    \"ema50_slope\": " + JsonPrice(ema50_slope) + ",\n";
   json += "    \"ema50_direction\": \"" + ema50_direction + "\",\n";
   json += "    \"ema200\": " + JsonPrice(trend_baseline_ma[1]) + ",\n";
   json += "    \"ema200_slope\": " + JsonPrice(ema200_slope) + ",\n";
   json += "    \"ema200_slope_threshold\": " + JsonPrice(ema200_slope_threshold) + ",\n";
   json += "    \"ema200_direction\": \"" + ema200_direction + "\",\n";
   json += "    \"atr\": " + JsonPrice(trend_atr[1]) + "\n";
   json += "  },\n";
   return json;
}

bool TryExportAIH4Screenshot(const datetime now_time)
{
   if(!InpExportAIH4Screenshot)
      return false;

   if(last_ai_h4_screenshot_export_time > 0 &&
      now_time - last_ai_h4_screenshot_export_time < InpAIH4ScreenshotExportSeconds)
      return false;

   const long chart_id = OpenAIH4ScreenshotChart();
   if(chart_id <= 0)
      return false;

   ChartNavigate(chart_id, CHART_END, 0);
   ChartRedraw(chart_id);
   Sleep(250);

   ResetLastError();
   const bool screenshot_ok = ChartScreenShot(chart_id,
                                              InpAIH4ScreenshotFile,
                                              InpAIH4ScreenshotWidth,
                                              InpAIH4ScreenshotHeight,
                                              ALIGN_RIGHT);
   const int screenshot_error = GetLastError();
   ChartClose(chart_id);

   if(!screenshot_ok)
   {
      Print("Failed to export AI H4 screenshot. file=",
            InpAIH4ScreenshotFile,
            ", error=", screenshot_error);
      return false;
   }

   last_ai_h4_screenshot_export_time = now_time;
   return true;
}

long OpenAIH4ScreenshotChart()
{
   ResetLastError();
   const long chart_id = ChartOpen(_Symbol, InpAIH4ScreenshotTimeframe);
   if(chart_id <= 0)
   {
      Print("Failed to open AI screenshot chart. symbol=", _Symbol,
            ", timeframe=", EnumToString(InpAIH4ScreenshotTimeframe),
            ", error=", GetLastError());
      return 0;
   }

   Sleep(500);
   return chart_id;
}

string JsonPrice(const double value)
{
   return DoubleToString(NormalizePrice(value), _Digits);
}

string TradeSignalToText(const TradeSignal signal)
{
   if(signal == SIGNAL_BUY)
      return "BUY";
   if(signal == SIGNAL_SELL)
      return "SELL";
   return "NONE";
}

string SignalToText(const TradeSignal signal)
{
   return TradeSignalToText(signal);
}

string ConfiguredSymbol()
{
   if(InpTargetSymbol == "")
      return _Symbol;

   return InpTargetSymbol;
}

TradeSignal AIChartLineRoleSide(const string role)
{
   if(StringFind(role, "BUY_") == 0)
      return SIGNAL_BUY;
   if(StringFind(role, "SELL_") == 0)
      return SIGNAL_SELL;
   return SIGNAL_NONE;
}

bool HasAIChartLineSuggestionPrice(const string json,
                                   const string role,
                                   const string active_line_name)
{
   double price = 0.0;
   return TryReadAIChartLinePrice(json, role, active_line_name, price);
}

bool HasAIChartLineSuggestionForSide(const string json, const TradeSignal side)
{
   if(side == SIGNAL_BUY)
   {
      return HasAIChartLineSuggestionPrice(json, "BUY_PULLBACK", InpBuyPullbackLineName) ||
             HasAIChartLineSuggestionPrice(json, "BUY_BREAKOUT", InpBuyBreakoutLineName) ||
             HasAIChartLineSuggestionPrice(json, "BUY_BREAKOUT_TRIGGER", InpBuyBreakoutTriggerLineName) ||
             HasAIChartLineSuggestionPrice(json, "BUY_RETEST_ENTRY", InpBuyRetestEntryLineName);
   }

   if(side == SIGNAL_SELL)
   {
      return HasAIChartLineSuggestionPrice(json, "SELL_PULLBACK", InpSellPullbackLineName) ||
             HasAIChartLineSuggestionPrice(json, "SELL_BREAKDOWN", InpSellBreakdownLineName) ||
             HasAIChartLineSuggestionPrice(json, "SELL_BREAKDOWN_TRIGGER", InpSellBreakdownTriggerLineName) ||
             HasAIChartLineSuggestionPrice(json, "SELL_RETEST_ENTRY", InpSellRetestEntryLineName);
   }

   return false;
}

bool HasAnyAIChartLineSuggestionPrice(const string json)
{
   return HasAIChartLineSuggestionForSide(json, SIGNAL_BUY) ||
          HasAIChartLineSuggestionForSide(json, SIGNAL_SELL);
}

void RemoveAIChartLineSuggestionsForSide(const TradeSignal side)
{
   if(side == SIGNAL_BUY)
   {
      RemoveOmittedAIChartLine(InpBuyPullbackLineName, ORDER_TYPE_BUY_LIMIT);
      RemoveOmittedAIChartLine(InpBuyBreakoutLineName, ORDER_TYPE_BUY_STOP);
      RemoveOmittedAIChartLine(InpBuyBreakoutTriggerLineName, ORDER_TYPE_BUY_STOP_LIMIT);
      RemoveOmittedAIChartLine(InpBuyRetestEntryLineName, ORDER_TYPE_BUY_STOP_LIMIT);
      return;
   }

   if(side == SIGNAL_SELL)
   {
      RemoveOmittedAIChartLine(InpSellPullbackLineName, ORDER_TYPE_SELL_LIMIT);
      RemoveOmittedAIChartLine(InpSellBreakdownLineName, ORDER_TYPE_SELL_STOP);
      RemoveOmittedAIChartLine(InpSellBreakdownTriggerLineName, ORDER_TYPE_SELL_STOP_LIMIT);
      RemoveOmittedAIChartLine(InpSellRetestEntryLineName, ORDER_TYPE_SELL_STOP_LIMIT);
   }
}

void RemoveAllAIChartLineSuggestions()
{
   RemoveAIChartLineSuggestionsForSide(SIGNAL_BUY);
   RemoveAIChartLineSuggestionsForSide(SIGNAL_SELL);
}

void TryApplyAIChartLineSuggestions()
{
   if(!InpEnableAIChartLineSuggestions)
      return;

   if(!ShouldCheckAIChartLineSuggestions())
      return;

   string json = "";
   string suggestion_source = "";
   if(!ReadActiveAIChartLineSuggestion(json, suggestion_source))
      return;

   if(!IsAIChartLineSuggestionUsable(json))
      return;

   const bool has_buy_side = HasAIChartLineSuggestionForSide(json, SIGNAL_BUY);
   const bool has_sell_side = HasAIChartLineSuggestionForSide(json, SIGNAL_SELL);
   if(!has_buy_side && !has_sell_side)
   {
      LogVerbose("AI chart-line suggestion file has no line prices; clearing current AI lines.");
      RemoveAllAIChartLineSuggestions();
      last_ai_chart_line_signature = "";
      ChartRedraw(0);
      return;
   }

   int applied_count = 0;
   int retained_count = 0;
   string signature = "ai_chart_lines=all_sides;";

   if(has_buy_side)
   {
      const TradeSignal allowed_side = SIGNAL_BUY;
      ApplyAIChartLineSuggestion(json,
                                 "BUY_PULLBACK",
                                 InpBuyPullbackLineName,
                                 ORDER_TYPE_BUY_LIMIT,
                                 InpChartLineBuyColor,
                                 STYLE_DASH,
                                 "AI buy pullback",
                                 allowed_side,
                                 applied_count,
                                 retained_count,
                                 signature);
      ApplyAIChartLineSuggestion(json,
                                 "BUY_BREAKOUT",
                                 InpBuyBreakoutLineName,
                                 ORDER_TYPE_BUY_STOP,
                                 InpChartLineBuyColor,
                                 STYLE_SOLID,
                                 "AI buy breakout",
                                 allowed_side,
                                 applied_count,
                                 retained_count,
                                 signature);

      const bool has_buy_trigger = HasAIChartLineSuggestionPrice(json,
                                                                 "BUY_BREAKOUT_TRIGGER",
                                                                 InpBuyBreakoutTriggerLineName);
      const bool has_buy_entry = HasAIChartLineSuggestionPrice(json,
                                                               "BUY_RETEST_ENTRY",
                                                               InpBuyRetestEntryLineName);
      if(has_buy_trigger && has_buy_entry)
      {
         ApplyAIChartLineSuggestion(json,
                                    "BUY_BREAKOUT_TRIGGER",
                                    InpBuyBreakoutTriggerLineName,
                                    ORDER_TYPE_BUY_STOP_LIMIT,
                                    InpChartLineBuyColor,
                                    STYLE_DOT,
                                    "AI buy breakout trigger",
                                    allowed_side,
                                    applied_count,
                                    retained_count,
                                    signature);
         ApplyAIChartLineSuggestion(json,
                                    "BUY_RETEST_ENTRY",
                                    InpBuyRetestEntryLineName,
                                    ORDER_TYPE_BUY_STOP_LIMIT,
                                    InpChartLineStopLimitEntryColor,
                                    STYLE_DOT,
                                    "AI buy retest entry",
                                    allowed_side,
                                    applied_count,
                                    retained_count,
                                    signature);
      }
      else
      {
         if(has_buy_trigger || has_buy_entry)
         {
            LogVerbose("Skipping AI buy retest lines: trigger and entry must be supplied together.");
            RemoveOmittedAIChartLine(InpBuyBreakoutTriggerLineName, ORDER_TYPE_BUY_STOP_LIMIT);
            RemoveOmittedAIChartLine(InpBuyRetestEntryLineName, ORDER_TYPE_BUY_STOP_LIMIT);
         }
         else
         {
            RetainOrRemoveOmittedAIChartLinePair("BUY_BREAKOUT_TRIGGER",
                                                InpBuyBreakoutTriggerLineName,
                                                "BUY_RETEST_ENTRY",
                                                InpBuyRetestEntryLineName,
                                                ORDER_TYPE_BUY_STOP_LIMIT,
                                                allowed_side,
                                                retained_count,
                                                signature);
         }
      }
   }
   else
   {
      RemoveAIChartLineSuggestionsForSide(SIGNAL_BUY);
   }

   if(has_sell_side)
   {
      const TradeSignal allowed_side = SIGNAL_SELL;
      ApplyAIChartLineSuggestion(json,
                                 "SELL_PULLBACK",
                                 InpSellPullbackLineName,
                                 ORDER_TYPE_SELL_LIMIT,
                                 InpChartLineSellColor,
                                 STYLE_DASH,
                                 "AI sell pullback",
                                 allowed_side,
                                 applied_count,
                                 retained_count,
                                 signature);
      ApplyAIChartLineSuggestion(json,
                                 "SELL_BREAKDOWN",
                                 InpSellBreakdownLineName,
                                 ORDER_TYPE_SELL_STOP,
                                 InpChartLineSellColor,
                                 STYLE_SOLID,
                                 "AI sell breakdown",
                                 allowed_side,
                                 applied_count,
                                 retained_count,
                                 signature);

      const bool has_sell_trigger = HasAIChartLineSuggestionPrice(json,
                                                                  "SELL_BREAKDOWN_TRIGGER",
                                                                  InpSellBreakdownTriggerLineName);
      const bool has_sell_entry = HasAIChartLineSuggestionPrice(json,
                                                                "SELL_RETEST_ENTRY",
                                                                InpSellRetestEntryLineName);
      if(has_sell_trigger && has_sell_entry)
      {
         ApplyAIChartLineSuggestion(json,
                                    "SELL_BREAKDOWN_TRIGGER",
                                    InpSellBreakdownTriggerLineName,
                                    ORDER_TYPE_SELL_STOP_LIMIT,
                                    InpChartLineSellColor,
                                    STYLE_DOT,
                                    "AI sell breakdown trigger",
                                    allowed_side,
                                    applied_count,
                                    retained_count,
                                    signature);
         ApplyAIChartLineSuggestion(json,
                                    "SELL_RETEST_ENTRY",
                                    InpSellRetestEntryLineName,
                                    ORDER_TYPE_SELL_STOP_LIMIT,
                                    InpChartLineStopLimitEntryColor,
                                    STYLE_DOT,
                                    "AI sell retest entry",
                                    allowed_side,
                                    applied_count,
                                    retained_count,
                                    signature);
      }
      else
      {
         if(has_sell_trigger || has_sell_entry)
         {
            LogVerbose("Skipping AI sell retest lines: trigger and entry must be supplied together.");
            RemoveOmittedAIChartLine(InpSellBreakdownTriggerLineName, ORDER_TYPE_SELL_STOP_LIMIT);
            RemoveOmittedAIChartLine(InpSellRetestEntryLineName, ORDER_TYPE_SELL_STOP_LIMIT);
         }
         else
         {
            RetainOrRemoveOmittedAIChartLinePair("SELL_BREAKDOWN_TRIGGER",
                                                InpSellBreakdownTriggerLineName,
                                                "SELL_RETEST_ENTRY",
                                                InpSellRetestEntryLineName,
                                                ORDER_TYPE_SELL_STOP_LIMIT,
                                                allowed_side,
                                                retained_count,
                                                signature);
         }
      }
   }
   else
   {
      RemoveAIChartLineSuggestionsForSide(SIGNAL_SELL);
   }

   if(applied_count + retained_count < 1)
   {
      LogVerbose("AI chart-line suggestion file has no usable prices.");
      return;
   }

   ChartRedraw(0);
   if(signature != last_ai_chart_line_signature)
   {
      Print("Applied AI chart-line suggestions. source=", suggestion_source,
            ", count=", IntegerToString(applied_count),
            ", retained=", IntegerToString(retained_count));
      last_ai_chart_line_signature = signature;
   }
}

bool ShouldCheckAIChartLineSuggestions()
{
   const datetime now_time = TimeCurrent();
   if(last_ai_chart_line_check_time > 0 &&
      now_time - last_ai_chart_line_check_time < InpAIChartLineCheckSeconds)
      return false;

   last_ai_chart_line_check_time = now_time;
   return true;
}

bool ShouldUseAIBacktestReplay()
{
   return InpEnableAIBacktestReplay && (bool)MQLInfoInteger(MQL_TESTER);
}

bool ReadActiveAIChartLineSuggestion(string &json, string &suggestion_source)
{
   json = "";
   suggestion_source = "";

   if(ShouldUseAIBacktestReplay())
   {
      suggestion_source = InpAIBacktestReplayFile + " (backtest replay)";
      return ReadAIBacktestReplaySuggestionFile(json);
   }

   suggestion_source = InpAIChartLineSuggestionFile;
   return ReadAIChartLineSuggestionFile(json);
}

bool ReadAIChartLineSuggestionFile(string &json)
{
   json = "";
   int open_flags = FILE_READ | FILE_TXT | FILE_ANSI;
   if(InpAIChartLineUseCommonFiles)
      open_flags |= FILE_COMMON;

   ResetLastError();
   const int file_handle = FileOpen(InpAIChartLineSuggestionFile, open_flags);
   if(file_handle == INVALID_HANDLE)
   {
      if(!warned_ai_suggestion_file_missing)
      {
         LogVerbose("AI chart-line suggestion file is not available: " +
                    InpAIChartLineSuggestionFile +
                    ". error=" + IntegerToString(GetLastError()));
         warned_ai_suggestion_file_missing = true;
      }
      return false;
   }

   warned_ai_suggestion_file_missing = false;
   while(!FileIsEnding(file_handle))
      json += FileReadString(file_handle);
   FileClose(file_handle);

   if(StringLen(json) < 1)
   {
      LogVerbose("AI chart-line suggestion file is empty: " +
                 InpAIChartLineSuggestionFile);
      return false;
   }

   return true;
}

bool ReadAIBacktestReplaySuggestionFile(string &json)
{
   json = "";
   string csv = "";
   if(!ReadAIBacktestReplayText(csv))
      return false;

   string lines[];
   const int line_count = StringSplit(csv, StringGetCharacter("\n", 0), lines);
   if(line_count < 1)
   {
      LogVerbose("AI backtest replay file is empty: " + InpAIBacktestReplayFile);
      return false;
   }

   string header_cells[];
   int header_count = 0;
   int first_data_line = -1;
   for(int i = 0; i < line_count; i++)
   {
      const string line = TrimString(lines[i]);
      if(line == "" || StringFind(line, "#") == 0)
         continue;

      header_count = SplitSimpleCSVLine(line, header_cells);
      first_data_line = i + 1;
      break;
   }

   if(header_count < 1 || first_data_line < 0)
   {
      LogVerbose("AI backtest replay file has no header: " + InpAIBacktestReplayFile);
      return false;
   }

   const int time_index = FindCSVColumn(header_cells, header_count, "time",
                                        "generated_at",
                                        "timestamp");
   if(time_index < 0)
   {
      LogVerbose("AI backtest replay file header must include time/generated_at/timestamp.");
      return false;
   }

   const int symbol_index = FindCSVColumn(header_cells, header_count, "symbol");
   const int expires_index = FindCSVColumn(header_cells, header_count, "expires_at");
   const int ttl_index = FindCSVColumn(header_cells, header_count, "ttl_seconds");
   const datetime now_time = TimeCurrent();
   datetime best_time = 0;
   datetime best_expires = 0;
   string best_cells[];
   int best_count = 0;

   for(int i = first_data_line; i < line_count; i++)
   {
      const string line = TrimString(lines[i]);
      if(line == "" || StringFind(line, "#") == 0)
         continue;

      string cells[];
      const int cell_count = SplitSimpleCSVLine(line, cells);
      if(cell_count <= time_index)
         continue;

      const datetime row_time = ParseReplayTime(CSVCell(cells, cell_count, time_index));
      if(row_time <= 0 || row_time > now_time)
         continue;

      if(symbol_index >= 0)
      {
         const string row_symbol = CSVCell(cells, cell_count, symbol_index);
         if(row_symbol != "" && row_symbol != _Symbol && row_symbol != InpTargetSymbol)
            continue;
      }

      datetime row_expires = 0;
      if(expires_index >= 0)
         row_expires = ParseReplayTime(CSVCell(cells, cell_count, expires_index));
      if(row_expires <= 0 && ttl_index >= 0)
      {
         const int ttl_seconds = (int)StringToInteger(CSVCell(cells, cell_count, ttl_index));
         if(ttl_seconds > 0)
            row_expires = row_time + ttl_seconds;
      }
      if(row_expires <= 0)
         row_expires = row_time + InpAIBacktestReplayMaxAgeSeconds;

      if(now_time > row_expires)
         continue;

      if(row_time >= best_time)
      {
         best_time = row_time;
         best_expires = row_expires;
         best_count = cell_count;
         ArrayResize(best_cells, best_count);
         for(int c = 0; c < best_count; c++)
            best_cells[c] = cells[c];
      }
   }

   if(best_time <= 0)
   {
      LogVerbose("No active AI backtest replay row for " +
                 TimeToString(now_time, TIME_DATE | TIME_SECONDS));
      return false;
   }

   json = BuildAIBacktestReplayJson(header_cells,
                                    header_count,
                                    best_cells,
                                    best_count,
                                    best_time,
                                    best_expires);
   return true;
}

bool ReadAIBacktestReplayText(string &text)
{
   text = "";
   int open_flags = FILE_READ | FILE_TXT | FILE_ANSI;
   if(InpAIBacktestReplayUseCommonFiles)
      open_flags |= FILE_COMMON;

   ResetLastError();
   const int file_handle = FileOpen(InpAIBacktestReplayFile, open_flags);
   if(file_handle == INVALID_HANDLE)
   {
      if(!warned_ai_backtest_replay_file_missing)
      {
         LogVerbose("AI backtest replay file is not available: " +
                    InpAIBacktestReplayFile +
                    ". error=" + IntegerToString(GetLastError()));
         warned_ai_backtest_replay_file_missing = true;
      }
      return false;
   }

   warned_ai_backtest_replay_file_missing = false;
   while(!FileIsEnding(file_handle))
      text += FileReadString(file_handle) + "\n";
   FileClose(file_handle);

   return StringLen(text) > 0;
}

string BuildAIBacktestReplayJson(const string &header_cells[],
                                 const int header_count,
                                 const string &cells[],
                                 const int cell_count,
                                 const datetime generated_at,
                                 const datetime expires_at)
{
   string json = "{\n";
   json += "  \"symbol\": \"" + _Symbol + "\",\n";
   json += "  \"generated_at\": " + IntegerToString((long)generated_at) + ",\n";
   json += "  \"expires_at\": " + IntegerToString((long)expires_at) + ",\n";
   json += "  \"source\": \"ai_backtest_replay\",\n";
   json += "  \"lines\": {";

   bool has_line = false;
   AppendAIBacktestReplayLine(json, has_line, header_cells, header_count, cells, cell_count, "BUY_PULLBACK");
   AppendAIBacktestReplayLine(json, has_line, header_cells, header_count, cells, cell_count, "BUY_BREAKOUT");
   AppendAIBacktestReplayLine(json, has_line, header_cells, header_count, cells, cell_count, "BUY_BREAKOUT_TRIGGER");
   AppendAIBacktestReplayLine(json, has_line, header_cells, header_count, cells, cell_count, "BUY_RETEST_ENTRY");
   AppendAIBacktestReplayLine(json, has_line, header_cells, header_count, cells, cell_count, "SELL_PULLBACK");
   AppendAIBacktestReplayLine(json, has_line, header_cells, header_count, cells, cell_count, "SELL_BREAKDOWN");
   AppendAIBacktestReplayLine(json, has_line, header_cells, header_count, cells, cell_count, "SELL_BREAKDOWN_TRIGGER");
   AppendAIBacktestReplayLine(json, has_line, header_cells, header_count, cells, cell_count, "SELL_RETEST_ENTRY");

   if(has_line)
      json += "\n";
   json += "  }\n";
   json += "}\n";
   return json;
}

void AppendAIBacktestReplayLine(string &json,
                                bool &has_line,
                                const string &header_cells[],
                                const int header_count,
                                const string &cells[],
                                const int cell_count,
                                const string role)
{
   int column_index = FindCSVColumn(header_cells, header_count, role);
   if(column_index < 0)
      column_index = FindCSVColumn(header_cells, header_count, "BTC_" + role);
   if(column_index < 0)
      return;

   const string value = CSVCell(cells, cell_count, column_index);
   if(value == "")
      return;

   const double price = StringToDouble(value);
   if(price <= 0.0)
      return;

   if(has_line)
      json += ",\n";
   else
      json += "\n";

   json += "    \"" + role + "\": " + JsonPrice(price);
   has_line = true;
}

int SplitSimpleCSVLine(const string line, string &cells[])
{
   const int count = StringSplit(line, StringGetCharacter(",", 0), cells);
   for(int i = 0; i < count; i++)
      cells[i] = TrimString(cells[i]);
   return count;
}

int FindCSVColumn(const string &header_cells[],
                  const int header_count,
                  const string first_name,
                  const string second_name = "",
                  const string third_name = "")
{
   const string first = NormalizeCSVColumnName(first_name);
   const string second = NormalizeCSVColumnName(second_name);
   const string third = NormalizeCSVColumnName(third_name);

   for(int i = 0; i < header_count; i++)
   {
      const string column_name = NormalizeCSVColumnName(header_cells[i]);
      if(column_name == first ||
         (second != "" && column_name == second) ||
         (third != "" && column_name == third))
         return i;
   }

   return -1;
}

string CSVCell(const string &cells[], const int cell_count, const int index)
{
   if(index < 0 || index >= cell_count)
      return "";
   return TrimString(cells[index]);
}

datetime ParseReplayTime(const string raw_value)
{
   string value = TrimString(raw_value);
   if(value == "")
      return 0;

   const bool looks_like_epoch = StringFind(value, ".") < 0 &&
                                 StringFind(value, "-") < 0 &&
                                 StringFind(value, ":") < 0 &&
                                 StringFind(value, " ") < 0 &&
                                 StringFind(value, "T") < 0;
   if(looks_like_epoch)
      return NormalizeAISuggestionTime(StringToDouble(value));

   StringReplace(value, "T", " ");
   StringReplace(value, "-", ".");
   return StringToTime(value);
}

string NormalizeCSVColumnName(const string raw_value)
{
   string value = TrimString(raw_value);
   if(StringLen(value) > 0 && StringGetCharacter(value, 0) == 65279)
      value = StringSubstr(value, 1);
   StringToUpper(value);
   return value;
}

string TrimString(string value)
{
   StringTrimLeft(value);
   StringTrimRight(value);
   return value;
}

bool IsAIChartLineSuggestionUsable(const string json)
{
   if(InpAIChartLineRequireSymbolMatch)
   {
      string symbol = "";
      if(!TryReadJsonString(json, "symbol", symbol))
      {
         LogVerbose("Skipping AI chart-line suggestions: missing symbol.");
         return false;
      }

      if(symbol != _Symbol && symbol != InpTargetSymbol)
      {
         LogVerbose("Skipping AI chart-line suggestions: symbol mismatch. file_symbol=" +
                    symbol +
                    ", chart_symbol=" +
                    _Symbol);
         return false;
      }
   }

   double expires_at_value = 0.0;
   const bool has_expires_at = TryReadJsonNumber(json, "expires_at", expires_at_value);
   if(has_expires_at)
   {
      const datetime expires_at = NormalizeAISuggestionTime(expires_at_value);
      if(TimeCurrent() > expires_at)
      {
         LogVerbose("Skipping AI chart-line suggestions: expired at " +
                    TimeToString(expires_at, TIME_DATE | TIME_SECONDS));
         return false;
      }
   }

   double generated_at_value = 0.0;
   bool has_generated_at = TryReadJsonNumber(json, "generated_at", generated_at_value);
   if(!has_generated_at)
      has_generated_at = TryReadJsonNumber(json, "timestamp", generated_at_value);

   if(has_generated_at)
   {
      const datetime generated_at = NormalizeAISuggestionTime(generated_at_value);
      const int age_seconds = (int)(TimeGMT() - generated_at);
      const int max_age_seconds = ShouldUseAIBacktestReplay()
                                  ? InpAIBacktestReplayMaxAgeSeconds
                                  : InpAIChartLineSuggestionMaxAgeSeconds;
      if(age_seconds > max_age_seconds ||
         age_seconds < -max_age_seconds)
      {
         LogVerbose("Skipping AI chart-line suggestions: generated_at is outside max age. generated_at=" +
                    TimeToString(generated_at, TIME_DATE | TIME_SECONDS));
         return false;
      }
   }

   if(InpAIChartLineRequireFreshTimestamp && !has_expires_at && !has_generated_at)
   {
      LogVerbose("Skipping AI chart-line suggestions: missing generated_at/timestamp/expires_at.");
      return false;
   }

   return true;
}

datetime NormalizeAISuggestionTime(double value)
{
   if(value > 100000000000.0)
      value = value / 1000.0;
   return (datetime)value;
}

void ApplyAIChartLineSuggestion(const string json,
                                const string role,
                                const string active_line_name,
                                const ENUM_ORDER_TYPE order_type,
                                const color line_color,
                                const ENUM_LINE_STYLE line_style,
                                const string tooltip,
                                const TradeSignal allowed_side,
                                int &applied_count,
                                int &retained_count,
                                string &signature)
{
   const TradeSignal role_side = AIChartLineRoleSide(role);
   if(allowed_side != SIGNAL_NONE &&
      role_side != SIGNAL_NONE &&
      role_side != allowed_side)
   {
      RemoveOmittedAIChartLine(active_line_name, order_type);
      LogVerbose("Skipping AI chart line " + role +
                 ": H4 EMA200 allows only " +
                 TradeSignalToText(allowed_side) +
                 " lines.");
      return;
   }

   double price = 0.0;
   if(!TryReadAIChartLinePrice(json, role, active_line_name, price))
   {
      RetainOrRemoveOmittedAIChartLine(role,
                                       active_line_name,
                                       order_type,
                                       allowed_side,
                                       retained_count,
                                       signature);
      return;
   }

   price = NormalizePrice(AdjustedAIChartLineSuggestionPrice(role, price));
   if(price <= 0.0)
      return;

   if(EnsureAIChartLine(active_line_name, price, line_color, line_style, tooltip))
   {
      DeleteInactiveCommonIndicatorLine(active_line_name);
      TouchAIChartLine(active_line_name);
      applied_count++;
      signature += active_line_name + "=" + DoubleToString(price, _Digits) + ";";
   }
}

double AdjustedAIChartLineSuggestionPrice(const string role, const double price)
{
   if(InpAILimitFillNudgePoints <= 0 || price <= 0.0)
      return price;

   const double nudge = InpAILimitFillNudgePoints * _Point;
   if(role == "BUY_PULLBACK")
      return price + nudge;
   if(role == "SELL_PULLBACK")
      return price - nudge;
   return price;
}

void RetainOrRemoveOmittedAIChartLine(const string role,
                                      const string active_line_name,
                                      const ENUM_ORDER_TYPE order_type,
                                      const TradeSignal allowed_side,
                                      int &retained_count,
                                      string &signature)
{
   const TradeSignal role_side = AIChartLineRoleSide(role);
   if(!InpAIKeepOmittedSameDirectionLines ||
      role_side == SIGNAL_NONE ||
      role_side != allowed_side ||
      !IsOmittedAIChartLineStillFresh(active_line_name))
   {
      RemoveOmittedAIChartLine(active_line_name, order_type);
      return;
   }

   RetainOmittedAIChartLine(active_line_name, retained_count, signature);
}

void RetainOrRemoveOmittedAIChartLinePair(const string first_role,
                                          const string first_line_name,
                                          const string second_role,
                                          const string second_line_name,
                                          const ENUM_ORDER_TYPE order_type,
                                          const TradeSignal allowed_side,
                                          int &retained_count,
                                          string &signature)
{
   const TradeSignal first_side = AIChartLineRoleSide(first_role);
   const TradeSignal second_side = AIChartLineRoleSide(second_role);
   if(!InpAIKeepOmittedSameDirectionLines ||
      first_side != allowed_side ||
      second_side != allowed_side ||
      !IsOmittedAIChartLineStillFresh(first_line_name) ||
      !IsOmittedAIChartLineStillFresh(second_line_name))
   {
      RemoveOmittedAIChartLine(first_line_name, order_type);
      RemoveOmittedAIChartLine(second_line_name, order_type);
      return;
   }

   RetainOmittedAIChartLine(first_line_name, retained_count, signature);
   RetainOmittedAIChartLine(second_line_name, retained_count, signature);
}

void RetainOmittedAIChartLine(const string active_line_name,
                              int &retained_count,
                              string &signature)
{
   double retained_price = 0.0;
   ReadChartLinePrice(active_line_name, retained_price);
   retained_count++;
   signature += active_line_name + "=retained:" + DoubleToString(retained_price, _Digits) + ";";
   LogVerbose("Retained omitted same-direction AI chart line " +
              active_line_name +
              " for sticky AI suggestions.");
}

bool IsOmittedAIChartLineStillFresh(const string active_line_name)
{
   if(active_line_name == "" || !ChartLineObjectExists(active_line_name))
      return false;

   const string key = AIChartLineTouchKey(active_line_name);
   const datetime now_time = TimeCurrent();
   if(!GlobalVariableCheck(key))
   {
      GlobalVariableSet(key, (double)now_time);
      return true;
   }

   const datetime touched_at = (datetime)GlobalVariableGet(key);
   if(touched_at <= 0)
      return false;

   return now_time - touched_at <= InpAIKeepOmittedSameDirectionSeconds;
}

void TouchAIChartLine(const string active_line_name)
{
   if(active_line_name == "")
      return;
   GlobalVariableSet(AIChartLineTouchKey(active_line_name), (double)TimeCurrent());
}

string AIChartLineTouchKey(const string active_line_name)
{
   return "CodexAILineTouch." + _Symbol + "." + active_line_name;
}

void RemoveOmittedAIChartLine(const string active_line_name,
                              const ENUM_ORDER_TYPE order_type)
{
   if(!InpAIRemoveOmittedChartLines || active_line_name == "")
      return;

   if(ChartLineObjectExists(active_line_name))
   {
      DeleteChartLineObject(active_line_name);
      Print("Deleted omitted AI chart line ", active_line_name);
   }

   GlobalVariableDel(AIChartLineTouchKey(active_line_name));

   if(!InpDryRun)
      RemoveChartLinePendingOrder(order_type);
}

bool TryReadAIChartLinePrice(const string json,
                             const string role,
                             const string active_line_name,
                             double &price)
{
   price = 0.0;
   if(TryReadJsonNumber(json, active_line_name, price))
      return price > 0.0;
   if(TryReadJsonNumber(json, role, price))
      return price > 0.0;
   return false;
}

bool EnsureAIChartLine(const string object_name,
                       const double price,
                       const color line_color,
                       const ENUM_LINE_STYLE line_style,
                       const string tooltip)
{
   if(object_name == "" || price <= 0.0)
      return false;

   const double normalized_price = NormalizePrice(price);
   if(ChartLineObjectExists(object_name))
   {
      const long object_type = ObjectGetInteger(0, object_name, OBJPROP_TYPE);
      if(object_type != OBJ_HLINE)
      {
         LogVerbose("Skipping AI update for non-horizontal chart line: " + object_name);
         return false;
      }

      ObjectSetDouble(0, object_name, OBJPROP_PRICE, 0, normalized_price);
   }
   else
   {
      ResetLastError();
      if(!ObjectCreate(0, object_name, OBJ_HLINE, 0, 0, normalized_price))
      {
         Print("Failed to create AI chart line ", object_name,
               ". price=", DoubleToString(normalized_price, _Digits),
               ", error=", GetLastError());
         return false;
      }
   }

   ObjectSetInteger(0, object_name, OBJPROP_COLOR, line_color);
   ObjectSetInteger(0, object_name, OBJPROP_STYLE, line_style);
   ObjectSetInteger(0, object_name, OBJPROP_WIDTH, 2);
   ApplyChartLineObjectInteraction(object_name, false);
   ObjectSetString(0, object_name, OBJPROP_TOOLTIP, tooltip);
   EnsureChartLineLabel(object_name, normalized_price, line_color);
   return true;
}

void DeleteInactiveCommonIndicatorLine(const string active_line_name)
{
   if(active_line_name == "" || InpCommonIndicatorInactiveSuffix == "")
      return;

   const string inactive_line_name = active_line_name + InpCommonIndicatorInactiveSuffix;
   DeleteChartLineLabel(inactive_line_name);
   if(ObjectFind(0, inactive_line_name) >= 0)
      ObjectDelete(0, inactive_line_name);
}

bool TryReadJsonNumber(const string json, const string key, double &value)
{
   value = 0.0;
   const int key_pos = FindJsonKey(json, key);
   if(key_pos < 0)
      return false;

   const int colon_pos = StringFind(json, ":", key_pos + StringLen(key) + 2);
   if(colon_pos < 0)
      return false;

   string token = "";
   bool in_string = false;
   for(int i = colon_pos + 1; i < StringLen(json); i++)
   {
      const string ch = StringSubstr(json, i, 1);
      if(token == "" && IsJsonWhitespace(ch))
         continue;
      if(token == "" && ch == "\"")
      {
         in_string = true;
         continue;
      }
      if((!in_string && (ch == "," || ch == "}" || ch == "]")) ||
         (in_string && ch == "\""))
         break;
      if(IsJsonWhitespace(ch))
         continue;
      token += ch;
   }

   if(token == "")
      return false;

   value = StringToDouble(token);
   return true;
}

bool TryReadJsonString(const string json, const string key, string &value)
{
   value = "";
   const int key_pos = FindJsonKey(json, key);
   if(key_pos < 0)
      return false;

   const int colon_pos = StringFind(json, ":", key_pos + StringLen(key) + 2);
   if(colon_pos < 0)
      return false;

   int start_pos = -1;
   for(int i = colon_pos + 1; i < StringLen(json); i++)
   {
      const string ch = StringSubstr(json, i, 1);
      if(IsJsonWhitespace(ch))
         continue;
      if(ch != "\"")
         return false;
      start_pos = i + 1;
      break;
   }

   if(start_pos < 0)
      return false;

   const int end_pos = StringFind(json, "\"", start_pos);
   if(end_pos < 0)
      return false;

   value = StringSubstr(json, start_pos, end_pos - start_pos);
   return value != "";
}

int FindJsonKey(const string json, const string key)
{
   return StringFind(json, "\"" + key + "\"");
}

bool IsJsonWhitespace(const string ch)
{
   return ch == " " || ch == "\r" || ch == "\n" || ch == "\t";
}

void LogInactiveCommonIndicatorLines()
{
   if(!InpVerboseLogs)
      return;

   const datetime now_time = TimeCurrent();
   if(last_inactive_chart_line_log_time > 0 &&
      now_time - last_inactive_chart_line_log_time < 60)
      return;

   const int inactive_count = CountInactiveCommonIndicatorLines();
   if(inactive_count < 1)
      return;

   last_inactive_chart_line_log_time = now_time;
   LogVerbose("Found " + IntegerToString(inactive_count) +
              " inactive common chart-line indicator line(s). Drag an " +
              InpCommonIndicatorInactiveSuffix +
              " line once to arm the matching EA order line.");
}

int CountInactiveCommonIndicatorLines()
{
   int count = 0;
   if(InactiveCommonIndicatorLineExists(InpBuyPullbackLineName))
      count++;
   if(InactiveCommonIndicatorLineExists(InpSellPullbackLineName))
      count++;
   if(InactiveCommonIndicatorLineExists(InpBuyBreakoutLineName))
      count++;
   if(InactiveCommonIndicatorLineExists(InpSellBreakdownLineName))
      count++;
   if(InactiveCommonIndicatorLineExists(InpBuyBreakoutTriggerLineName))
      count++;
   if(InactiveCommonIndicatorLineExists(InpBuyRetestEntryLineName))
      count++;
   if(InactiveCommonIndicatorLineExists(InpSellBreakdownTriggerLineName))
      count++;
   if(InactiveCommonIndicatorLineExists(InpSellRetestEntryLineName))
      count++;
   return count;
}

bool InactiveCommonIndicatorLineExists(const string active_line_name)
{
   return active_line_name != "" &&
          ObjectFind(0, active_line_name + InpCommonIndicatorInactiveSuffix) >= 0;
}

bool ShouldProcessChartLines()
{
   const datetime now_time = TimeCurrent();
   if(last_chart_line_check_time > 0 &&
      now_time - last_chart_line_check_time < InpChartLineCheckSeconds)
      return false;

   last_chart_line_check_time = now_time;
   return true;
}

void TryAutoCreateChartLines(const double &fast_ma[],
                             const double &slow_ma[],
                             const double atr,
                             const MqlRates &rates[])
{
   TradeSignal bias = GetHigherTimeframeBias();
   if(InpAutoCreateChartLinesRequireTrendFilter && bias == SIGNAL_NONE)
   {
      LogVerbose("Skipping auto chart-line creation: H4 trend filter is neutral.");
      return;
   }

   double breakout_high = 0.0;
   double breakout_low = 0.0;
   GetBreakoutRange(rates, breakout_high, breakout_low);

   if(InpAutoCreateBothDirections)
   {
      AutoCreateBuyChartLines(fast_ma, slow_ma, atr, breakout_high);
      AutoCreateSellChartLines(fast_ma, slow_ma, atr, breakout_low);
      ChartRedraw(0);
      return;
   }

   if(bias == SIGNAL_BUY || (!InpAutoCreateChartLinesRequireTrendFilter && bias == SIGNAL_NONE))
   {
      AutoCreateBuyChartLines(fast_ma, slow_ma, atr, breakout_high);
      if(InpAutoRemoveInactiveDirection && bias == SIGNAL_BUY)
         RemoveSellChartLineSide();
   }

   if(bias == SIGNAL_SELL || (!InpAutoCreateChartLinesRequireTrendFilter && bias == SIGNAL_NONE))
   {
      AutoCreateSellChartLines(fast_ma, slow_ma, atr, breakout_low);
      if(InpAutoRemoveInactiveDirection && bias == SIGNAL_SELL)
         RemoveBuyChartLineSide();
   }

   ChartRedraw(0);
}

void AutoCreateBuyChartLines(const double &fast_ma[],
                             const double &slow_ma[],
                             const double atr,
                             const double breakout_high)
{
   const double buy_limit = NormalizePrice(MathMin(fast_ma[1], slow_ma[1]) -
                                           atr * InpLimitOffsetATR);
   const double buy_stop = NormalizePrice(breakout_high + atr * InpStopEntryOffsetATR);
   const double buy_stop_limit_entry = NormalizePrice(buy_stop - atr * InpStopLimitRetestATR);

   EnsureAutoChartLine(InpBuyPullbackLineName,
                       buy_limit,
                       InpChartLineBuyColor,
                       STYLE_DASH,
                       "auto buy pullback");
   EnsureAutoChartLine(InpBuyBreakoutLineName,
                       buy_stop,
                       InpChartLineBuyColor,
                       STYLE_SOLID,
                       "auto buy breakout");
   EnsureAutoChartLine(InpBuyBreakoutTriggerLineName,
                       buy_stop,
                       InpChartLineBuyColor,
                       STYLE_DOT,
                       "auto buy breakout trigger");
   EnsureAutoChartLine(InpBuyRetestEntryLineName,
                       buy_stop_limit_entry,
                       InpChartLineStopLimitEntryColor,
                       STYLE_DOT,
                       "auto buy retest entry");
}

void AutoCreateSellChartLines(const double &fast_ma[],
                              const double &slow_ma[],
                              const double atr,
                              const double breakout_low)
{
   const double sell_limit = NormalizePrice(MathMax(fast_ma[1], slow_ma[1]) +
                                            atr * InpLimitOffsetATR);
   const double sell_stop = NormalizePrice(breakout_low - atr * InpStopEntryOffsetATR);
   const double sell_stop_limit_entry = NormalizePrice(sell_stop + atr * InpStopLimitRetestATR);

   EnsureAutoChartLine(InpSellPullbackLineName,
                       sell_limit,
                       InpChartLineSellColor,
                       STYLE_DASH,
                       "auto sell pullback");
   EnsureAutoChartLine(InpSellBreakdownLineName,
                       sell_stop,
                       InpChartLineSellColor,
                       STYLE_SOLID,
                       "auto sell breakdown");
   EnsureAutoChartLine(InpSellBreakdownTriggerLineName,
                       sell_stop,
                       InpChartLineSellColor,
                       STYLE_DOT,
                       "auto sell breakdown trigger");
   EnsureAutoChartLine(InpSellRetestEntryLineName,
                       sell_stop_limit_entry,
                       InpChartLineStopLimitEntryColor,
                       STYLE_DOT,
                       "auto sell retest entry");
}

void RemoveBuyChartLineSide()
{
   DeleteChartLineObject(InpBuyPullbackLineName);
   DeleteChartLineObject(InpBuyBreakoutLineName);
   DeleteChartLineObject(InpBuyBreakoutTriggerLineName);
   DeleteChartLineObject(InpBuyRetestEntryLineName);
   RemoveChartLinePendingOrder(ORDER_TYPE_BUY_LIMIT);
   RemoveChartLinePendingOrder(ORDER_TYPE_BUY_STOP);
   RemoveChartLinePendingOrder(ORDER_TYPE_BUY_STOP_LIMIT);
}

void RemoveSellChartLineSide()
{
   DeleteChartLineObject(InpSellPullbackLineName);
   DeleteChartLineObject(InpSellBreakdownLineName);
   DeleteChartLineObject(InpSellBreakdownTriggerLineName);
   DeleteChartLineObject(InpSellRetestEntryLineName);
   RemoveChartLinePendingOrder(ORDER_TYPE_SELL_LIMIT);
   RemoveChartLinePendingOrder(ORDER_TYPE_SELL_STOP);
   RemoveChartLinePendingOrder(ORDER_TYPE_SELL_STOP_LIMIT);
}

void DeleteChartLineObject(const string object_name)
{
   DeleteChartLineLabel(object_name);

   if(!ChartLineObjectExists(object_name))
      return;

   if(ObjectDelete(0, object_name))
      Print("Deleted inactive chart line ", object_name);
   else
      Print("Failed to delete inactive chart line ", object_name,
            ". error=", GetLastError());
}

void CleanupLegacyChartLineObjects()
{
   DeleteLegacyChartLineObject("BTC_BUY_LIMIT");
   DeleteLegacyChartLineObject("BTC_SELL_LIMIT");
   DeleteLegacyChartLineObject("BTC_BUY_STOP");
   DeleteLegacyChartLineObject("BTC_SELL_STOP");
   DeleteLegacyChartLineObject("BTC_BUY_STOP_LIMIT_TRIGGER");
   DeleteLegacyChartLineObject("BTC_BUY_STOP_LIMIT_ENTRY");
   DeleteLegacyChartLineObject("BTC_SELL_STOP_LIMIT_TRIGGER");
   DeleteLegacyChartLineObject("BTC_SELL_STOP_LIMIT_ENTRY");
}

void DeleteLegacyChartLineObject(const string object_name)
{
   if(IsActiveChartLineName(object_name))
      return;
   DeleteChartLineObject(object_name);
}

bool IsActiveChartLineName(const string object_name)
{
   return object_name == InpBuyPullbackLineName ||
          object_name == InpSellPullbackLineName ||
          object_name == InpBuyBreakoutLineName ||
          object_name == InpSellBreakdownLineName ||
          object_name == InpBuyBreakoutTriggerLineName ||
          object_name == InpBuyRetestEntryLineName ||
          object_name == InpSellBreakdownTriggerLineName ||
          object_name == InpSellRetestEntryLineName;
}

void RemoveChartLinePendingOrder(const ENUM_ORDER_TYPE order_type)
{
   const int orders_total = OrdersTotal();
   for(int i = orders_total - 1; i >= 0; i--)
   {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((ulong)OrderGetInteger(ORDER_MAGIC) != InpChartLineMagicNumber)
         continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) != order_type)
         continue;

      if(InpDryRun)
      {
         LogVerbose("DRY-RUN remove inactive chart-line order. ticket=" +
                    IntegerToString((long)ticket) +
                    ", type=" + OrderTypeToText(order_type));
         continue;
      }

      trade.SetExpertMagicNumber(InpChartLineMagicNumber);
      if(trade.OrderDelete(ticket))
      {
         Print("Removed inactive chart-line order. ticket=", IntegerToString((long)ticket),
               ", type=", OrderTypeToText(order_type));
      }
      else
      {
         Print("Failed to remove inactive chart-line order. ticket=",
               IntegerToString((long)ticket),
               ", type=", OrderTypeToText(order_type),
               ", retcode=", IntegerToString((int)trade.ResultRetcode()),
               ", description=", trade.ResultRetcodeDescription(),
               ", last_error=", GetLastError());
      }
   }
}

void RemoveAllChartLinePendingOrders()
{
   RemoveChartLinePendingOrder(ORDER_TYPE_BUY_LIMIT);
   RemoveChartLinePendingOrder(ORDER_TYPE_SELL_LIMIT);
   RemoveChartLinePendingOrder(ORDER_TYPE_BUY_STOP);
   RemoveChartLinePendingOrder(ORDER_TYPE_SELL_STOP);
   RemoveChartLinePendingOrder(ORDER_TYPE_BUY_STOP_LIMIT);
   RemoveChartLinePendingOrder(ORDER_TYPE_SELL_STOP_LIMIT);
}

void RemoveAllManagedPendingOrders()
{
   const int orders_total = OrdersTotal();
   for(int i = orders_total - 1; i >= 0; i--)
   {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)OrderGetInteger(ORDER_MAGIC);
      if(!IsManagedMagic(magic))
         continue;

      const ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsManagedPendingType(type))
         continue;

      trade.SetExpertMagicNumber(magic);
      trade.SetDeviationInPoints(InpDeviationPoints);
      trade.SetTypeFillingBySymbol(_Symbol);
      if(trade.OrderDelete(ticket))
      {
         Print("Deleted managed pending order for model direct mode. ticket=",
               IntegerToString((long)ticket),
               ", type=", OrderTypeToText(type),
               ", magic=", IntegerToString((long)magic));
      }
      else
      {
         Print("Failed to delete managed pending order for model direct mode. ticket=",
               IntegerToString((long)ticket),
               ", type=", OrderTypeToText(type),
               ", retcode=", IntegerToString((int)trade.ResultRetcode()),
               ", description=", trade.ResultRetcodeDescription(),
               ", last_error=", GetLastError());
      }
   }
}

void RemoveOppositeChartLinePendingOrders(const TradeSignal allowed_side)
{
   if(allowed_side == SIGNAL_BUY)
   {
      RemoveChartLinePendingOrder(ORDER_TYPE_SELL_LIMIT);
      RemoveChartLinePendingOrder(ORDER_TYPE_SELL_STOP);
      RemoveChartLinePendingOrder(ORDER_TYPE_SELL_STOP_LIMIT);
   }
   else if(allowed_side == SIGNAL_SELL)
   {
      RemoveChartLinePendingOrder(ORDER_TYPE_BUY_LIMIT);
      RemoveChartLinePendingOrder(ORDER_TYPE_BUY_STOP);
      RemoveChartLinePendingOrder(ORDER_TYPE_BUY_STOP_LIMIT);
   }
}

bool EnsureAutoChartLine(const string object_name,
                         const double price,
                         const color line_color,
                         const ENUM_LINE_STYLE line_style,
                         const string tooltip)
{
   if(object_name == "" || price <= 0.0)
      return false;

   const double normalized_price = NormalizePrice(price);
   if(ChartLineObjectExists(object_name))
   {
      ApplyChartLineObjectInteraction(object_name, false);

      if(!InpAutoUpdateChartLines)
      {
         double current_price = normalized_price;
         ReadChartLinePrice(object_name, current_price);
         EnsureChartLineLabel(object_name, current_price, line_color);
         return true;
      }

      const long object_type = ObjectGetInteger(0, object_name, OBJPROP_TYPE);
      if(object_type != OBJ_HLINE)
      {
         double current_price = normalized_price;
         ReadChartLinePrice(object_name, current_price);
         EnsureChartLineLabel(object_name, current_price, line_color);
         return true;
      }

      ObjectSetDouble(0, object_name, OBJPROP_PRICE, 0, normalized_price);
      ObjectSetString(0, object_name, OBJPROP_TOOLTIP, tooltip);
      EnsureChartLineLabel(object_name, normalized_price, line_color);
      return true;
   }

   ResetLastError();
   if(!ObjectCreate(0, object_name, OBJ_HLINE, 0, 0, normalized_price))
   {
      Print("Failed to create chart line ", object_name,
            ". price=", DoubleToString(normalized_price, _Digits),
            ", error=", GetLastError());
      return false;
   }

   ObjectSetInteger(0, object_name, OBJPROP_COLOR, line_color);
   ObjectSetInteger(0, object_name, OBJPROP_STYLE, line_style);
   ObjectSetInteger(0, object_name, OBJPROP_WIDTH, 2);
   ApplyChartLineObjectInteraction(object_name, InpSelectAutoCreatedChartLines);
   ObjectSetString(0, object_name, OBJPROP_TOOLTIP, tooltip);
   EnsureChartLineLabel(object_name, normalized_price, line_color);
   Print("Created chart line ", object_name,
         " at ", DoubleToString(normalized_price, _Digits),
         " (", tooltip, ")");
   return true;
}

void ApplyChartLineObjectInteraction(const string object_name, const bool select_line)
{
   ObjectSetInteger(0, object_name, OBJPROP_SELECTABLE, true);
   if(select_line)
      ObjectSetInteger(0, object_name, OBJPROP_SELECTED, true);
   ObjectSetInteger(0, object_name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, object_name, OBJPROP_BACK, false);
   ObjectSetInteger(0, object_name, OBJPROP_ZORDER, 100);
}

void EnsureChartLineLabel(const string line_name, const double price, const color label_color)
{
   if(InpUseCommonChartLineIndicators)
      return;

   if(!InpShowChartLineLabels || line_name == "" || price <= 0.0)
      return;

   const string label_name = ChartLineLabelName(line_name);
   const int chart_period_seconds = MathMax(PeriodSeconds(_Period), 60);
   const datetime current_bar_time = iTime(_Symbol, _Period, 0);
   const datetime base_time = current_bar_time > 0 ? current_bar_time : TimeCurrent();
   const datetime label_time = base_time -
                               (datetime)(chart_period_seconds *
                                          MathMax(InpChartLineLabelBarsBack, 0));
   const double label_price = NormalizePrice(price);

   if(ObjectFind(0, label_name) < 0)
   {
      ResetLastError();
      if(!ObjectCreate(0, label_name, OBJ_TEXT, 0, label_time, label_price))
      {
         Print("Failed to create chart line label ", label_name,
               ". error=", GetLastError());
         return;
      }
   }
   else
   {
      ObjectMove(0, label_name, 0, label_time, label_price);
   }

   ObjectSetString(0, label_name, OBJPROP_TEXT, line_name + " ");
   ObjectSetString(0, label_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, label_name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, label_name, OBJPROP_COLOR, label_color);
   ObjectSetInteger(0, label_name, OBJPROP_ANCHOR, ANCHOR_RIGHT);
   ObjectSetInteger(0, label_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, label_name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, label_name, OBJPROP_BACK, false);
}

void DeleteChartLineLabel(const string line_name)
{
   if(line_name == "")
      return;

   const string label_name = ChartLineLabelName(line_name);
   if(ObjectFind(0, label_name) >= 0)
      ObjectDelete(0, label_name);
}

string ChartLineLabelName(const string line_name)
{
   return line_name + "_LABEL";
}

void TrySubmitChartLinePlans(const double atr, const MqlRates &rates[])
{
   TradeSignal h4_ema200_side = SIGNAL_NONE;

   if(CountManagedPendingOrders((long)InpChartLineMagicNumber) >= InpMaxChartLinePendingOrders)
   {
      LogVerbose("Skipping chart line trading: max chart-line pending orders reached.");
      return;
   }

   TradeSignal bias = SIGNAL_NONE;
   if(InpChartLineRequireTrendFilter)
   {
      bias = GetHigherTimeframeBias();
      if(bias == SIGNAL_NONE)
      {
         LogVerbose("Skipping chart line trading: H4 trend filter is neutral.");
         return;
      }
   }

   TrySubmitChartLineSingleOrder(InpBuyPullbackLineName,
                                 ORDER_TYPE_BUY_LIMIT,
                                 "CHART_LINE_BUY_PULLBACK",
                                 atr,
                                 rates,
                                 bias,
                                 h4_ema200_side);
   TrySubmitChartLineSingleOrder(InpSellPullbackLineName,
                                 ORDER_TYPE_SELL_LIMIT,
                                 "CHART_LINE_SELL_PULLBACK",
                                 atr,
                                 rates,
                                 bias,
                                 h4_ema200_side);
   TrySubmitChartLineSingleOrder(InpBuyBreakoutLineName,
                                 ORDER_TYPE_BUY_STOP,
                                 "CHART_LINE_BUY_BREAKOUT",
                                 atr,
                                 rates,
                                 bias,
                                 h4_ema200_side);
   TrySubmitChartLineSingleOrder(InpSellBreakdownLineName,
                                 ORDER_TYPE_SELL_STOP,
                                 "CHART_LINE_SELL_BREAKDOWN",
                                 atr,
                                 rates,
                                 bias,
                                 h4_ema200_side);
   TrySubmitChartLineStopLimit(InpBuyBreakoutTriggerLineName,
                               InpBuyRetestEntryLineName,
                               ORDER_TYPE_BUY_STOP_LIMIT,
                               "CHART_LINE_BUY_RETEST",
                               atr,
                               rates,
                               bias,
                               h4_ema200_side);
   TrySubmitChartLineStopLimit(InpSellBreakdownTriggerLineName,
                               InpSellRetestEntryLineName,
                               ORDER_TYPE_SELL_STOP_LIMIT,
                               "CHART_LINE_SELL_RETEST",
                               atr,
                               rates,
                               bias,
                               h4_ema200_side);
}

void TrySubmitChartLineSingleOrder(const string line_name,
                                   const ENUM_ORDER_TYPE order_type,
                                   const string mode,
                                   const double atr,
                                   const MqlRates &rates[],
                                   const TradeSignal bias,
                                   const TradeSignal h4_ema200_side)
{
   if(!ChartLineObjectExists(line_name))
      return;

   if(CountManagedPendingOrders((long)InpChartLineMagicNumber) >= InpMaxChartLinePendingOrders)
      return;

   if(!IsPendingTypeSupported(order_type))
      return;

   if(!IsChartLineDirectionAllowed(order_type, bias, h4_ema200_side))
      return;

   double line_price = 0.0;
   if(!ReadChartLinePrice(line_name, line_price))
      return;
   EnsureChartLineLabel(line_name,
                        line_price,
                        IsBuyType(order_type) ? InpChartLineBuyColor : InpChartLineSellColor);

   PendingPlan plan;
   ZeroMemory(plan);
   plan.mode = mode;
   plan.magic = InpChartLineMagicNumber;
   plan.type = order_type;
   plan.price = line_price;
   plan.expiration = BuildChartLineExpirationTime();
   plan.comment = ChartLineOrderComment(mode);

   BuildRiskFields(plan, atr);
   SubmitPlanIfValid(plan, rates);
}

void TrySubmitChartLineStopLimit(const string trigger_line_name,
                                 const string entry_line_name,
                                 const ENUM_ORDER_TYPE order_type,
                                 const string mode,
                                 const double atr,
                                 const MqlRates &rates[],
                                 const TradeSignal bias,
                                 const TradeSignal h4_ema200_side)
{
   const bool has_trigger = ChartLineObjectExists(trigger_line_name);
   const bool has_entry = ChartLineObjectExists(entry_line_name);
   if(!has_trigger && !has_entry)
      return;

   if(!has_trigger || !has_entry)
   {
      LogVerbose("Skipping " + mode + ": trigger and entry lines are both required.");
      return;
   }

   if(CountManagedPendingOrders((long)InpChartLineMagicNumber) >= InpMaxChartLinePendingOrders)
      return;

   if(!IsPendingTypeSupported(order_type))
      return;

   if(!IsChartLineDirectionAllowed(order_type, bias, h4_ema200_side))
      return;

   double trigger_price = 0.0;
   double entry_price = 0.0;
   if(!ReadChartLinePrice(trigger_line_name, trigger_price) ||
      !ReadChartLinePrice(entry_line_name, entry_price))
      return;
   EnsureChartLineLabel(trigger_line_name,
                        trigger_price,
                        IsBuyType(order_type) ? InpChartLineBuyColor : InpChartLineSellColor);
   EnsureChartLineLabel(entry_line_name,
                        entry_price,
                        InpChartLineStopLimitEntryColor);

   PendingPlan plan;
   ZeroMemory(plan);
   plan.mode = mode;
   plan.magic = InpChartLineMagicNumber;
   plan.type = order_type;
   plan.price = trigger_price;
   plan.stoplimit = entry_price;
   plan.expiration = BuildChartLineExpirationTime();
   plan.comment = ChartLineOrderComment(mode);

   BuildRiskFields(plan, atr);
   SubmitPlanIfValid(plan, rates);
}

bool IsChartLineDirectionAllowed(const ENUM_ORDER_TYPE order_type,
                                 const TradeSignal bias,
                                 const TradeSignal h4_ema200_side)
{
   if(!InpChartLineRequireTrendFilter)
      return true;

   if(IsBuyType(order_type) && bias != SIGNAL_BUY)
   {
      LogVerbose("Skipping chart line buy order: H4 trend filter is not bullish.");
      return false;
   }

   if(!IsBuyType(order_type) && bias != SIGNAL_SELL)
   {
      LogVerbose("Skipping chart line sell order: H4 trend filter is not bearish.");
      return false;
   }

   return true;
}

bool ReadChartLinePrice(const string object_name, double &price)
{
   price = 0.0;
   if(!ChartLineObjectExists(object_name))
      return false;

   const long object_type = ObjectGetInteger(0, object_name, OBJPROP_TYPE);
   if(object_type == OBJ_HLINE)
   {
      price = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 0);
   }
   else if(object_type == OBJ_TREND)
   {
      const datetime time_one = (datetime)ObjectGetInteger(0, object_name, OBJPROP_TIME, 0);
      const datetime time_two = (datetime)ObjectGetInteger(0, object_name, OBJPROP_TIME, 1);
      const double price_one = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 0);
      const double price_two = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 1);

      if(time_one <= 0 || time_two <= 0 || price_one <= 0.0 || price_two <= 0.0)
      {
         LogVerbose("Skipping chart line " + object_name + ": invalid trend line anchors.");
         return false;
      }

      if(time_one == time_two)
      {
         price = price_two;
      }
      else
      {
         const double time_ratio = (double)(TimeCurrent() - time_one) /
                                   (double)(time_two - time_one);
         price = price_one + (price_two - price_one) * time_ratio;
      }
   }
   else
   {
      LogVerbose("Skipping chart line " + object_name +
                 ": unsupported object type=" + IntegerToString(object_type));
      return false;
   }

   price = NormalizePrice(price);
   if(price <= 0.0)
   {
      LogVerbose("Skipping chart line " + object_name + ": invalid price.");
      return false;
   }

   return true;
}

void TrySubmitLimitReversion(const TradeSignal bias,
                             const double &fast_ma[],
                             const double &slow_ma[],
                             const double atr,
                             const MqlRates &rates[])
{
   if(CountManagedPendingOrders((long)InpLimitMagicNumber) >= InpMaxPendingOrdersPerMode)
      return;
   if(!IsPendingTypeSupported(ORDER_TYPE_BUY_LIMIT))
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   PendingPlan plan;
   ZeroMemory(plan);
   plan.mode = "LIMIT_REVERSION";
   plan.magic = InpLimitMagicNumber;
   plan.expiration = BuildExpirationTime();

   const double offset = atr * InpLimitOffsetATR;
   if(bias == SIGNAL_BUY)
   {
      plan.type = ORDER_TYPE_BUY_LIMIT;
      plan.price = NormalizePrice(MathMin(fast_ma[1], slow_ma[1]) - offset);
      if(plan.price >= tick.ask)
      {
         LogVerbose("Skipping limit reversion buy: limit price is not below ask.");
         return;
      }
   }
   else if(bias == SIGNAL_SELL)
   {
      plan.type = ORDER_TYPE_SELL_LIMIT;
      plan.price = NormalizePrice(MathMax(fast_ma[1], slow_ma[1]) + offset);
      if(plan.price <= tick.bid)
      {
         LogVerbose("Skipping limit reversion sell: limit price is not above bid.");
         return;
      }
   }
   else
   {
      return;
   }

   BuildRiskFields(plan, atr);
   plan.comment = "BTC pending limit";
   SubmitPlanIfValid(plan, rates);
}

void TrySubmitStopBreakout(const TradeSignal bias, const double atr, const MqlRates &rates[])
{
   if(CountManagedPendingOrders((long)InpStopMagicNumber) >= InpMaxPendingOrdersPerMode)
      return;
   if(!IsPendingTypeSupported(ORDER_TYPE_BUY_STOP))
      return;

   PendingPlan plan;
   ZeroMemory(plan);
   plan.mode = "STOP_BREAKOUT";
   plan.magic = InpStopMagicNumber;
   plan.expiration = BuildExpirationTime();

   double breakout_high = 0.0;
   double breakout_low = 0.0;
   GetBreakoutRange(rates, breakout_high, breakout_low);

   const double offset = atr * InpStopEntryOffsetATR;
   if(bias == SIGNAL_BUY)
   {
      plan.type = ORDER_TYPE_BUY_STOP;
      plan.price = NormalizePrice(breakout_high + offset);
   }
   else if(bias == SIGNAL_SELL)
   {
      plan.type = ORDER_TYPE_SELL_STOP;
      plan.price = NormalizePrice(breakout_low - offset);
   }
   else
   {
      return;
   }

   BuildRiskFields(plan, atr);
   plan.comment = "BTC pending stop";
   SubmitPlanIfValid(plan, rates);
}

void TrySubmitStopLimitRetest(const TradeSignal bias, const double atr, const MqlRates &rates[])
{
   if(CountManagedPendingOrders((long)InpStopLimitMagicNumber) >= InpMaxPendingOrdersPerMode)
      return;
   if(!IsPendingTypeSupported(ORDER_TYPE_BUY_STOP_LIMIT))
      return;

   PendingPlan plan;
   ZeroMemory(plan);
   plan.mode = "STOP_LIMIT_RETEST";
   plan.magic = InpStopLimitMagicNumber;
   plan.expiration = BuildExpirationTime();

   double breakout_high = 0.0;
   double breakout_low = 0.0;
   GetBreakoutRange(rates, breakout_high, breakout_low);

   const double trigger_offset = atr * InpStopEntryOffsetATR;
   const double retest_offset = atr * InpStopLimitRetestATR;
   if(bias == SIGNAL_BUY)
   {
      plan.type = ORDER_TYPE_BUY_STOP_LIMIT;
      plan.price = NormalizePrice(breakout_high + trigger_offset);
      plan.stoplimit = NormalizePrice(plan.price - retest_offset);
   }
   else if(bias == SIGNAL_SELL)
   {
      plan.type = ORDER_TYPE_SELL_STOP_LIMIT;
      plan.price = NormalizePrice(breakout_low - trigger_offset);
      plan.stoplimit = NormalizePrice(plan.price + retest_offset);
   }
   else
   {
      return;
   }

   BuildRiskFields(plan, atr);
   plan.comment = "BTC pending stop-limit";
   SubmitPlanIfValid(plan, rates);
}

void TrySubmitModelDirectEntry()
{
   datetime current_bar_time = iTime(_Symbol, InpSignalTimeframe, 0);
   if(current_bar_time <= 0 || current_bar_time == last_signal_bar_time)
      return;
   last_signal_bar_time = current_bar_time;

   double fast_ma[];
   double slow_ma[];
   double rsi_values[];
   double atr_values[];
   MqlRates rates[];
   if(!LoadSignalData(fast_ma, slow_ma, rsi_values, atr_values, rates))
      return;

   const double atr = atr_values[1];
   if(atr <= 0.0)
   {
      Print("Skipping model direct entry: invalid ATR value.");
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, "MODEL_DIRECT", "MISSING_ATR", 0.0, 0.0, 0.0, 0);
      return;
   }

   if(!IsTradeSetupAllowed(atr))
   {
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, "MODEL_DIRECT", "TRADE_SETUP_BLOCKED", 0.0, 0.0, 0.0, 0);
      return;
   }

   TradeSignal signal = SIGNAL_NONE;
   string model_reason = "";
   if(!GetModelDirectSignal(signal, model_reason))
   {
      LogVerbose("Skipping model direct entry: " + model_reason);
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, "MODEL_DIRECT", "MODEL_DIRECT_NO_SIGNAL", 0.0, 0.0, 0.0, 0);
      return;
   }

   string position_block_reason = "";
   if(IsModelDirectPositionBlocked(signal, position_block_reason))
   {
      LogVerbose("Skipping model direct " + TradeSignalToText(signal) + ": " + position_block_reason);
      AppendSignalSnapshot("SKIP", signal, "MODEL_DIRECT", position_block_reason, 0.0, 0.0, 0.0, 0);
      return;
   }

   if(IsCoexistencePositionGuardHit(signal, position_block_reason))
   {
      LogVerbose("Skipping model direct " + TradeSignalToText(signal) + ": " + position_block_reason);
      AppendSignalSnapshot("SKIP", signal, "MODEL_DIRECT", position_block_reason, 0.0, 0.0, 0.0, 0);
      return;
   }

   SubmitModelDirectMarketOrder(signal, atr, model_reason);
}

bool IsModelDirectPositionBlocked(const TradeSignal signal, string &reason)
{
   reason = "";
   if(signal == SIGNAL_NONE)
   {
      reason = "MODEL_DIRECT_NO_DIRECTION";
      return true;
   }

   const int same_direction_positions = CountManagedPositionsForSignal(signal, 0);
   if(same_direction_positions >= InpMaxModelDirectPositionsPerDirection)
   {
      reason = "MODEL_DIRECT_POSITION_LIMIT";
      return true;
   }

   if(InpModelDirectBlockOppositePositions)
   {
      const TradeSignal opposite_signal = signal == SIGNAL_BUY ? SIGNAL_SELL : SIGNAL_BUY;
      const int opposite_positions = CountManagedPositionsForSignal(opposite_signal, 0);
      if(opposite_positions > 0)
      {
         reason = "MODEL_DIRECT_OPPOSITE_POSITION_EXISTS";
         return true;
      }
   }

   return false;
}

bool IsWindowsCoexistenceMagic(const ulong magic)
{
   if(IsManagedMagic(magic))
      return true;
   return(InpWindowsCoexistenceMode &&
          InpPeerTrendMagicNumber > 0 &&
          magic == InpPeerTrendMagicNumber);
}

int CountCoexistencePositions(const TradeSignal signal_filter = SIGNAL_NONE)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!IsWindowsCoexistenceMagic(magic))
         continue;

      if(signal_filter != SIGNAL_NONE)
      {
         const ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         const TradeSignal position_signal = position_type == POSITION_TYPE_BUY ? SIGNAL_BUY : SIGNAL_SELL;
         if(position_signal != signal_filter)
            continue;
      }

      count++;
   }
   return count;
}

double SumCoexistenceVolume()
{
   double volume = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!IsWindowsCoexistenceMagic(magic))
         continue;

      volume += PositionGetDouble(POSITION_VOLUME);
   }
   return volume;
}

bool IsCoexistencePositionGuardHit(const TradeSignal signal, string &reason)
{
   reason = "";
   if(!InpWindowsCoexistenceMode)
      return false;

   if(InpBlockOppositeCoexistencePositions && signal != SIGNAL_NONE)
   {
      const TradeSignal opposite_signal = signal == SIGNAL_BUY ? SIGNAL_SELL : SIGNAL_BUY;
      if(CountCoexistencePositions(opposite_signal) > 0)
      {
         reason = "WINDOWS_BTC_OPPOSITE_POSITION_EXISTS";
         return true;
      }
   }

   if(InpMaxCombinedBTCPositions > 0 &&
      CountCoexistencePositions() >= InpMaxCombinedBTCPositions)
   {
      reason = "WINDOWS_BTC_COMBINED_POSITION_LIMIT";
      return true;
   }

   if(InpMaxCombinedBTCVolume > 0.0 &&
      SumCoexistenceVolume() >= InpMaxCombinedBTCVolume - 0.0000001)
   {
      reason = "WINDOWS_BTC_COMBINED_VOLUME_LIMIT";
      return true;
   }

   return false;
}

int CountManagedPositionsForSignal(const TradeSignal signal, const long magic)
{
   int count = 0;
   const ENUM_POSITION_TYPE expected_type = signal == SIGNAL_BUY
                                            ? POSITION_TYPE_BUY
                                            : POSITION_TYPE_SELL;
   const int positions_total = PositionsTotal();
   for(int i = positions_total - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const long position_magic = PositionGetInteger(POSITION_MAGIC);
      if(magic > 0)
      {
         if(position_magic != magic)
            continue;
      }
      else if(!IsManagedMagic((ulong)position_magic))
      {
         continue;
      }

      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == expected_type)
         count++;
   }

   return count;
}

bool SubmitModelDirectMarketOrder(const TradeSignal signal,
                                  const double atr,
                                  const string model_reason)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
   {
      Print("Skipping model direct entry: unable to read tick. error=", GetLastError());
      return false;
   }

   const double entry_price = signal == SIGNAL_BUY ? tick.ask : tick.bid;
   if(entry_price <= 0.0)
      return false;

   double order_risk_percent = InpRiskPerOrderPercent;
   double model_stop_atr = InpStopLossATR;
   double model_target_atr = InpStopLossATR * InpTakeProfitRewardRisk;
   int model_max_positions = InpMaxModelDirectPositionsPerDirection;
   int model_cooldown_minutes = 0;
   string model_execution_reason = "default execution inputs";
   if(InpUseModelDirectTrading && InpUseModelExecutionPlan)
   {
      if(!GetModelExecutionPlan(signal,
                                order_risk_percent,
                                model_stop_atr,
                                model_target_atr,
                                model_max_positions,
                                model_cooldown_minutes,
                                model_execution_reason))
      {
         Print("Skipping model direct entry: missing model execution plan. ", model_execution_reason);
         AppendSignalSnapshot("SKIP", signal, "MODEL_DIRECT", "MODEL_EXECUTION_PLAN_MISSING", 0.0, 0.0, 0.0, 0);
         return false;
      }
   }

   if(InpUseModelDirectTrading && InpUseModelExecutionPlan &&
      model_max_positions > 0 &&
      CountModelStrategyPositions(signal) >= model_max_positions)
   {
      Print("Skipping model direct ", TradeSignalToText(signal),
            ": model execution max same-direction positions reached. max=",
            IntegerToString(model_max_positions));
      AppendSignalSnapshot("SKIP", signal, "MODEL_DIRECT", "MODEL_EXECUTION_POSITION_LIMIT", 0.0, 0.0, 0.0, 0);
      return false;
   }

   double stop_distance = NormalizePriceDistance(atr * model_stop_atr);
   if(InpEnableMaxLossStop)
   {
      const double max_loss_stop_distance = NormalizePriceDistance(InpMaxLossStopPoints * _Point);
      stop_distance = MathMin(stop_distance, max_loss_stop_distance);
   }

   const double take_profit_distance = NormalizePriceDistance(atr * model_target_atr);
   double sl = 0.0;
   double tp = 0.0;
   if(signal == SIGNAL_BUY)
   {
      sl = NormalizePrice(entry_price - stop_distance);
      tp = NormalizePrice(entry_price + take_profit_distance);
   }
   else
   {
      sl = NormalizePrice(entry_price + stop_distance);
      tp = NormalizePrice(entry_price - take_profit_distance);
   }

   bool used_min_volume_fallback = false;
   double effective_risk_percent = order_risk_percent;
   double volume = CalculatePositionSizeForRisk(stop_distance,
                                                order_risk_percent,
                                                used_min_volume_fallback,
                                                effective_risk_percent);
   if(volume <= 0.0)
   {
      Print("Skipping model direct ", TradeSignalToText(signal),
            ": calculated volume is below minimum or fallback risk cap. stop_distance=",
            DoubleToString(stop_distance, _Digits),
            ", risk_percent=", DoubleToString(effective_risk_percent, 2));
      AppendSignalSnapshot("SKIP", signal, "MODEL_DIRECT", "VOLUME_BELOW_MINIMUM", 0.0, sl, tp, 0);
      return false;
   }

   volume = CapVolumeForSmallAccount(volume, "MODEL_DIRECT");
   if(volume <= 0.0)
   {
      AppendSignalSnapshot("SKIP", signal, "MODEL_DIRECT", "MAX_VOLUME_CAP_BELOW_MIN", 0.0, sl, tp, 0);
      return false;
   }

   string comment = "BTC model direct";
   int comment_hold_bars = 0;
   if(InpUseModelDirectTrading && InpUseModelExecutionPlan)
   {
      double comment_trail_start_atr = 0.0;
      double comment_trail_distance_atr = 0.0;
      string comment_management_reason = "";
      if(GetModelPositionManagementPlan(signal,
                                        comment_trail_start_atr,
                                        comment_trail_distance_atr,
                                        comment_hold_bars,
                                        comment_management_reason) &&
         comment_hold_bars > 0)
      {
         comment += " H" + IntegerToString(comment_hold_bars);
      }
   }

   Print(InpDryRun ? "DRY-RUN MODEL_DIRECT" : "SUBMIT MODEL_DIRECT",
         ": direction=", TradeSignalToText(signal),
         ", magic=", IntegerToString((long)InpModelDirectMagicNumber),
         ", volume=", DoubleToString(volume, VolumeDigits()),
         ", entry=", DoubleToString(entry_price, _Digits),
         ", sl=", DoubleToString(sl, _Digits),
         ", tp=", DoubleToString(tp, _Digits),
         ", risk_percent=", DoubleToString(effective_risk_percent, 3),
         ", min_volume_fallback=", BoolToText(used_min_volume_fallback),
         ", execution=", model_execution_reason,
         ", model=", model_reason);

   if(InpDryRun)
   {
      AppendSignalSnapshot("DRY-RUN", signal, "MODEL_DIRECT", model_reason, volume, sl, tp, 0);
      return true;
   }

   trade.SetExpertMagicNumber(InpModelDirectMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   bool ok = false;
   if(signal == SIGNAL_BUY)
      ok = trade.Buy(volume, _Symbol, 0.0, sl, tp, comment);
   else if(signal == SIGNAL_SELL)
      ok = trade.Sell(volume, _Symbol, 0.0, sl, tp, comment);

   if(!ok)
   {
      Print("Failed to submit model direct ", TradeSignalToText(signal),
            ". retcode=", IntegerToString((int)trade.ResultRetcode()),
            ", description=", trade.ResultRetcodeDescription(),
            ", last_error=", GetLastError());
      AppendSignalSnapshot("ERROR", signal, "MODEL_DIRECT", "ORDER_FAILED", volume, sl, tp, 0);
      return false;
   }

   const ulong order_ticket = trade.ResultOrder();
   Print("Model direct order submitted. direction=", TradeSignalToText(signal),
         ", ticket=", IntegerToString((long)order_ticket),
         ", volume=", DoubleToString(volume, VolumeDigits()),
         ", sl=", DoubleToString(sl, _Digits),
         ", tp=", DoubleToString(tp, _Digits));
   MarkModelRecommendationEntry(signal);
   AppendSignalSnapshot("ORDER", signal, "MODEL_DIRECT", "PLACED", volume, sl, tp, order_ticket);
   SendTelegramModelDirectNotification(signal, volume, trade.ResultPrice(), sl, tp, stop_distance, model_reason);
   return true;
}

void GetBreakoutRange(const MqlRates &rates[], double &range_high, double &range_low)
{
   range_high = rates[1].high;
   range_low = rates[1].low;
   for(int i = 2; i <= InpBreakoutLookbackBars + 1; i++)
   {
      range_high = MathMax(range_high, rates[i].high);
      range_low = MathMin(range_low, rates[i].low);
   }
}

void BuildRiskFields(PendingPlan &plan, const double atr)
{
   const double strategy_stop_distance = NormalizePriceDistance(atr * InpStopLossATR);
   const double take_profit_distance = strategy_stop_distance * InpTakeProfitRewardRisk;

   plan.stop_distance = strategy_stop_distance;
   if(InpEnableMaxLossStop)
   {
      const double max_loss_stop_distance = NormalizePriceDistance(InpMaxLossStopPoints * _Point);
      plan.stop_distance = MathMin(plan.stop_distance, max_loss_stop_distance);
   }

   if(IsBuyType(plan.type))
   {
      const double fill_price = PlanFillPrice(plan);
      plan.sl = NormalizePrice(fill_price - plan.stop_distance);
      plan.tp = NormalizePrice(fill_price + take_profit_distance);
   }
   else
   {
      const double fill_price = PlanFillPrice(plan);
      plan.sl = NormalizePrice(fill_price + plan.stop_distance);
      plan.tp = NormalizePrice(fill_price - take_profit_distance);
   }

   plan.used_min_volume_fallback = false;
   plan.risk_percent = InpRiskPerOrderPercent;
   plan.volume = CalculatePositionSize(plan.stop_distance,
                                       plan.used_min_volume_fallback,
                                       plan.risk_percent);
   plan.volume = CapVolumeForSmallAccount(plan.volume, plan.mode);
}

void SubmitPlanIfValid(PendingPlan &plan, const MqlRates &rates[])
{
   if(CountManagedPendingOrders(0) >= InpMaxManagedPendingOrders)
   {
      LogVerbose("Skipping " + plan.mode + ": max managed pending orders reached.");
      return;
   }

   if(plan.volume <= 0.0)
   {
      Print("Skipping ", plan.mode,
            ": calculated volume is below minimum or fallback risk cap. stop_distance=",
            DoubleToString(plan.stop_distance, _Digits),
            ", risk_percent=", DoubleToString(plan.risk_percent, 2));
      return;
   }

   if(!IsEntryPriceValid(plan))
      return;

   if(IsChartLineMode(plan.mode) &&
      CountChartLinePositionsForPlan(plan) >= InpMaxChartLinePositionsPerMode)
   {
      const int active_positions = CountChartLinePositionsForPlan(plan);
      RemoveChartLinePendingOrder(plan.type);
      LogVerbose("Skipping " + plan.mode +
                 ": active chart-line position limit reached. active_positions=" +
                 IntegerToString(active_positions) +
                 ", max_positions=" + IntegerToString(InpMaxChartLinePositionsPerMode));
      return;
   }

   if(IsChartLineMode(plan.mode) && TryUpdateExistingChartLineOrder(plan))
      return;

   if(IsRecentlyDuplicated(plan, rates))
      return;

   SubmitPlan(plan);
}

double CalculatePositionSize(const double stop_distance,
                             bool &used_min_volume_fallback,
                             double &effective_risk_percent)
{
   return(CalculatePositionSizeForRisk(stop_distance,
                                       InpRiskPerOrderPercent,
                                       used_min_volume_fallback,
                                       effective_risk_percent));
}

double CalculatePositionSizeForRisk(const double stop_distance,
                                    const double risk_percent,
                                    bool &used_min_volume_fallback,
                                    double &effective_risk_percent)
{
   const double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   const double risk_amount = balance * risk_percent / 100.0;
   const double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   const double tick_value_loss = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   const double tick_value = tick_value_loss > 0.0
                             ? tick_value_loss
                             : SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   const double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   const double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(balance <= 0.0 || risk_amount <= 0.0 || stop_distance <= 0.0 ||
      tick_size <= 0.0 || tick_value <= 0.0 || min_volume <= 0.0 ||
      max_volume <= 0.0 || volume_step <= 0.0)
   {
      Print("Volume sizing diagnostics: invalid symbol/account data. balance=",
            DoubleToString(balance, 2),
            ", stop_distance=", DoubleToString(stop_distance, _Digits),
            ", tick_size=", DoubleToString(tick_size, _Digits),
            ", tick_value=", DoubleToString(tick_value, 8),
            ", min_volume=", DoubleToString(min_volume, 4),
            ", step=", DoubleToString(volume_step, 4));
      return 0.0;
   }

   const double loss_per_lot = stop_distance / tick_size * tick_value;
   if(loss_per_lot <= 0.0)
      return 0.0;

   double raw_volume = risk_amount / loss_per_lot;
   double volume = NormalizeVolumeFloor(raw_volume, volume_step);

   if(volume < min_volume)
   {
      const double min_volume_risk_percent = loss_per_lot * min_volume / balance * 100.0;
      if(InpUseMinVolumeFallback && min_volume_risk_percent <= InpMaxFallbackRiskPercent)
      {
         used_min_volume_fallback = true;
         effective_risk_percent = min_volume_risk_percent;
         volume = min_volume;
         Print("Using minimum-volume fallback. raw_volume=", DoubleToString(raw_volume, 6),
               ", min_volume=", DoubleToString(min_volume, VolumeDigits()),
               ", estimated_risk_percent=", DoubleToString(min_volume_risk_percent, 3),
               ", fallback_cap_percent=", DoubleToString(InpMaxFallbackRiskPercent, 3));
      }
      else
      {
         Print("Volume sizing diagnostics: raw volume below minimum. raw_volume=",
               DoubleToString(raw_volume, 6),
               ", min_volume=", DoubleToString(min_volume, VolumeDigits()),
               ", estimated_min_volume_risk_percent=",
               DoubleToString(min_volume_risk_percent, 3),
               ", fallback_enabled=", BoolToText(InpUseMinVolumeFallback),
               ", fallback_cap_percent=", DoubleToString(InpMaxFallbackRiskPercent, 3),
               ", balance=", DoubleToString(balance, 2),
               ", risk_amount=", DoubleToString(risk_amount, 2),
               ", stop_distance=", DoubleToString(stop_distance, _Digits),
               ", loss_per_lot=", DoubleToString(loss_per_lot, 2));
         return 0.0;
      }
   }

   volume = MathMin(volume, max_volume);
   volume = NormalizeVolumeFloor(volume, volume_step);
   return NormalizeDouble(volume, VolumeDigits());
}

double CapVolumeForSmallAccount(const double volume, const string context)
{
   if(volume <= 0.0 || InpMaxVolumePerTrade <= 0.0 || volume <= InpMaxVolumePerTrade)
      return volume;

   const double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double capped_volume = NormalizeVolumeFloor(InpMaxVolumePerTrade, volume_step);

   if(capped_volume < min_volume)
   {
      Print("Skipping ", context,
            ": max volume cap is below broker minimum. cap=",
            DoubleToString(InpMaxVolumePerTrade, VolumeDigits()),
            ", min_volume=",
            DoubleToString(min_volume, VolumeDigits()));
      return 0.0;
   }

   Print("Capping Windows pending EA volume. context=", context,
         ", original=", DoubleToString(volume, VolumeDigits()),
         ", capped=", DoubleToString(capped_volume, VolumeDigits()));
   return NormalizeDouble(capped_volume, VolumeDigits());
}

double NormalizeVolumeFloor(const double volume, const double volume_step)
{
   if(volume_step <= 0.0)
      return 0.0;
   return MathFloor(volume / volume_step) * volume_step;
}

datetime TodayStartTime()
{
   MqlDateTime parts;
   TimeToStruct(TimeCurrent(), parts);
   parts.hour = 0;
   parts.min = 0;
   parts.sec = 0;
   return StructToTime(parts);
}

double GetTodayClosedPnL()
{
   if(!HistorySelect(TodayStartTime(), TimeCurrent()))
      return 0.0;

   double pnl = 0.0;
   const int total_deals = HistoryDealsTotal();
   for(int i = 0; i < total_deals; ++i)
   {
      const ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket == 0)
         continue;
      if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      if(!IsWindowsCoexistenceMagic(magic))
         continue;

      const ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      pnl += HistoryDealGetDouble(deal_ticket, DEAL_PROFIT) +
             HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION) +
             HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
   }

   return pnl;
}

int CountConsecutiveClosedLosses()
{
   if(!HistorySelect(0, TimeCurrent()))
      return 0;

   int losses = 0;
   const int total_deals = HistoryDealsTotal();
   for(int i = total_deals - 1; i >= 0; --i)
   {
      const ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket == 0)
         continue;
      if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      if(!IsWindowsCoexistenceMagic(magic))
         continue;

      const ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      const double pnl = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT) +
                         HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION) +
                         HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
      if(pnl < 0.0)
      {
         losses++;
         continue;
      }

      break;
   }

   return losses;
}

bool IsSmallAccountGuardHit()
{
   const double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(InpMinEquityToTrade > 0.0 && equity < InpMinEquityToTrade)
   {
      LogVerbose("Skipping entry: small-account equity guard active. equity=" +
                 DoubleToString(equity, 2) +
                 ", min_equity=" +
                 DoubleToString(InpMinEquityToTrade, 2));
      return true;
   }

   if(InpMaxDailyLossMoney > 0.0)
   {
      const double today_pnl = GetTodayClosedPnL();
      if(today_pnl <= -InpMaxDailyLossMoney)
      {
         LogVerbose("Skipping entry: small-account daily loss guard active. today_pnl=" +
                    DoubleToString(today_pnl, 2) +
                    ", limit=" +
                    DoubleToString(InpMaxDailyLossMoney, 2));
         return true;
      }
   }

   if(InpMaxConsecutiveLosses > 0)
   {
      const int losses = CountConsecutiveClosedLosses();
      if(losses >= InpMaxConsecutiveLosses)
      {
         LogVerbose("Skipping entry: small-account consecutive-loss guard active. losses=" +
                    IntegerToString(losses) +
                    ", max=" +
                    IntegerToString(InpMaxConsecutiveLosses));
         return true;
      }
   }

   return false;
}

int VolumeDigits()
{
   const double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(volume_step <= 0.0)
      return 2;
   int digits = 0;
   double step = volume_step;
   while(digits < 8 && MathAbs(step - MathRound(step)) > 0.00000001)
   {
      step *= 10.0;
      digits++;
   }
   return digits;
}

bool IsEntryPriceValid(const PendingPlan &plan)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
   {
      Print("Skipping ", plan.mode, ": unable to read tick. error=", GetLastError());
      return false;
   }

   const double stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   const double min_distance = MathMax(stops_level, _Point);

   if(plan.type == ORDER_TYPE_BUY_LIMIT && plan.price >= tick.ask - min_distance)
   {
      LogInvalidPrice(plan, "buy limit must be below ask by stops level");
      return false;
   }
   if(plan.type == ORDER_TYPE_SELL_LIMIT && plan.price <= tick.bid + min_distance)
   {
      LogInvalidPrice(plan, "sell limit must be above bid by stops level");
      return false;
   }
   if(plan.type == ORDER_TYPE_BUY_STOP && plan.price <= tick.ask + min_distance)
   {
      LogInvalidPrice(plan, "buy stop must be above ask by stops level");
      return false;
   }
   if(plan.type == ORDER_TYPE_SELL_STOP && plan.price >= tick.bid - min_distance)
   {
      LogInvalidPrice(plan, "sell stop must be below bid by stops level");
      return false;
   }
   if(plan.type == ORDER_TYPE_BUY_STOP_LIMIT)
   {
      if(plan.price <= tick.ask + min_distance || plan.stoplimit >= plan.price - min_distance)
      {
         LogInvalidPrice(plan, "buy stop-limit requires trigger above ask and limit below trigger");
         return false;
      }
   }
   if(plan.type == ORDER_TYPE_SELL_STOP_LIMIT)
   {
      if(plan.price >= tick.bid - min_distance || plan.stoplimit <= plan.price + min_distance)
      {
         LogInvalidPrice(plan, "sell stop-limit requires trigger below bid and limit above trigger");
         return false;
      }
   }

   const double fill_price = PlanFillPrice(plan);
   if(IsBuyType(plan.type))
   {
      if(plan.sl >= fill_price || plan.tp <= fill_price)
      {
         LogInvalidPrice(plan, "buy SL/TP are invalid");
         return false;
      }
   }
   else
   {
      if(plan.sl <= fill_price || plan.tp >= fill_price)
      {
         LogInvalidPrice(plan, "sell SL/TP are invalid");
         return false;
      }
   }

   return true;
}

bool IsPendingTypeSupported(const ENUM_ORDER_TYPE type)
{
   const long order_mode = SymbolInfoInteger(_Symbol, SYMBOL_ORDER_MODE);
   long flag = SYMBOL_ORDER_LIMIT;
   if(type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_SELL_STOP)
      flag = SYMBOL_ORDER_STOP;
   else if(type == ORDER_TYPE_BUY_STOP_LIMIT || type == ORDER_TYPE_SELL_STOP_LIMIT)
      flag = SYMBOL_ORDER_STOP_LIMIT;

   if((order_mode & flag) != flag)
   {
      LogVerbose("Skipping: symbol does not support " + OrderTypeToText(type) +
                 ". order_mode=" + IntegerToString(order_mode));
      return false;
   }
   return true;
}

bool IsRecentlyDuplicated(const PendingPlan &plan, const MqlRates &rates[])
{
   const double duplicate_distance = MathMax(_Point, (rates[1].high - rates[1].low) * 0.10);
   const int orders_total = OrdersTotal();
   for(int i = orders_total - 1; i >= 0; i--)
   {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((ulong)OrderGetInteger(ORDER_MAGIC) != plan.magic)
         continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) != plan.type)
         continue;

      const double existing_price = OrderGetDouble(ORDER_PRICE_OPEN);
      if(MathAbs(existing_price - plan.price) <= duplicate_distance)
      {
         LogVerbose("Skipping " + plan.mode + ": similar pending order already exists. ticket=" +
                    IntegerToString((long)ticket));
         return true;
      }
   }

   return false;
}

bool TryUpdateExistingChartLineOrder(const PendingPlan &plan)
{
   if(InpDryRun || plan.magic != InpChartLineMagicNumber)
      return false;

   const ulong ticket = FindChartLinePendingOrder(plan.type);
   if(ticket == 0)
      return false;

   if(!OrderSelect(ticket))
      return true;

   const double current_price = OrderGetDouble(ORDER_PRICE_OPEN);
   const double current_sl = OrderGetDouble(ORDER_SL);
   const double current_tp = OrderGetDouble(ORDER_TP);
   const double current_stoplimit = OrderGetDouble(ORDER_PRICE_STOPLIMIT);
   const double current_volume = OrderGetDouble(ORDER_VOLUME_CURRENT);

   if(MathAbs(current_price - plan.price) <= _Point &&
      MathAbs(current_sl - plan.sl) <= _Point &&
      MathAbs(current_tp - plan.tp) <= _Point &&
      MathAbs(current_stoplimit - plan.stoplimit) <= _Point)
   {
      LogVerbose("Chart line order already matches plan. ticket=" +
                 IntegerToString((long)ticket) +
                 ", type=" + OrderTypeToText(plan.type));
      return true;
   }

   trade.SetExpertMagicNumber(plan.magic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   const bool ok = trade.OrderModify(ticket,
                                     plan.price,
                                     plan.sl,
                                     plan.tp,
                                     ORDER_TIME_SPECIFIED,
                                     plan.expiration,
                                     plan.stoplimit);
   if(!ok)
   {
      Print("Failed to modify chart line order. ticket=", IntegerToString((long)ticket),
            ", type=", OrderTypeToText(plan.type),
            ", retcode=", IntegerToString((int)trade.ResultRetcode()),
            ", description=", trade.ResultRetcodeDescription(),
            ", last_error=", GetLastError());
      return true;
   }

   Print("Chart line order modified. ticket=", IntegerToString((long)ticket),
         ", type=", OrderTypeToText(plan.type),
         ", current_volume=", DoubleToString(current_volume, VolumeDigits()),
         ", desired_volume=", DoubleToString(plan.volume, VolumeDigits()),
         ", price=", DoubleToString(plan.price, _Digits),
         ", stoplimit=", DoubleToString(plan.stoplimit, _Digits),
         ", sl=", DoubleToString(plan.sl, _Digits),
         ", tp=", DoubleToString(plan.tp, _Digits));
   return true;
}

ulong FindChartLinePendingOrder(const ENUM_ORDER_TYPE type)
{
   const int orders_total = OrdersTotal();
   for(int i = orders_total - 1; i >= 0; i--)
   {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((ulong)OrderGetInteger(ORDER_MAGIC) != InpChartLineMagicNumber)
         continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) != type)
         continue;

      return ticket;
   }

   return 0;
}

int CountChartLinePositionsForPlan(const PendingPlan &plan)
{
   const string expected_comment = ChartLineOrderComment(plan.mode);
   const ENUM_POSITION_TYPE expected_type = (IsBuyType(plan.type) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
   const double expected_price = PlanFillPrice(plan);
   const double fallback_price_tolerance = MathMax(_Point * 10.0, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) * 10.0);
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpChartLineMagicNumber)
         continue;

      const string comment = PositionGetString(POSITION_COMMENT);
      if(comment == expected_comment)
      {
         count++;
         continue;
      }

      if(comment == "" &&
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == expected_type &&
         MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - expected_price) <= fallback_price_tolerance)
      {
         count++;
      }
   }
   return count;
}

int CountManagedPendingOrders(const long magic)
{
   int count = 0;
   const int orders_total = OrdersTotal();
   for(int i = orders_total - 1; i >= 0; i--)
   {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;

      const long order_magic = OrderGetInteger(ORDER_MAGIC);
      if(magic > 0)
      {
         if(order_magic != magic)
            continue;
      }
      else if(!IsManagedMagic((ulong)order_magic))
      {
         continue;
      }

      const ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(IsManagedPendingType(type))
         count++;
   }
   return count;
}

bool ManageProfitFloorStops()
{
   if(!InpEnableProfitFloorStop)
      return false;

   bool modify_attempted = false;
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return false;

   const int positions_total = PositionsTotal();
   for(int i = positions_total - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!IsManagedMagic(magic))
         continue;

      const ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_type != POSITION_TYPE_BUY && position_type != POSITION_TYPE_SELL)
         continue;

      const double profit = PositionGetDouble(POSITION_PROFIT);
      const double lock_money = ProfitFloorLockMoneyForProfit(profit);
      if(lock_money <= 0.0)
         continue;

      const double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      const double volume = PositionGetDouble(POSITION_VOLUME);
      const double current_sl = PositionGetDouble(POSITION_SL);
      const double current_tp = PositionGetDouble(POSITION_TP);
      double target_sl = 0.0;
      if(!BuildProfitFloorStopPrice(position_type,
                                    open_price,
                                    volume,
                                    lock_money,
                                    tick,
                                    target_sl))
      {
         LogVerbose("Skipping profit floor stop: unable to build valid SL. ticket=" +
                    IntegerToString((long)ticket) +
                    ", profit=" + DoubleToString(profit, 2) +
                    ", lock_money=" + DoubleToString(lock_money, 2));
         continue;
      }

      const bool improve_sl = IsProfitFloorStopImprovement(position_type,
                                                           current_sl,
                                                           target_sl);
      const bool remove_tp = InpProfitFloorRemoveTakeProfit && current_tp > 0.0;
      if(!improve_sl && !remove_tp)
         continue;

      if(!improve_sl)
         target_sl = current_sl;

      modify_attempted = true;
      Print("Profit floor stop update. ticket=", IntegerToString((long)ticket),
            ", magic=", IntegerToString((long)magic),
            ", profit=", DoubleToString(profit, 2),
            ", lock_money=", DoubleToString(lock_money, 2),
            ", current_sl=", DoubleToString(current_sl, _Digits),
            ", target_sl=", DoubleToString(target_sl, _Digits),
            ", current_tp=", DoubleToString(current_tp, _Digits),
            ", target_tp=", DoubleToString(InpProfitFloorRemoveTakeProfit ? 0.0 : current_tp, _Digits),
            ", dry_run=", BoolToText(InpDryRun));

      if(InpDryRun)
         continue;

      trade.SetExpertMagicNumber(magic);
      trade.SetDeviationInPoints(InpDeviationPoints);
      trade.SetTypeFillingBySymbol(_Symbol);
      if(trade.PositionModify(ticket,
                              target_sl,
                              InpProfitFloorRemoveTakeProfit ? 0.0 : current_tp))
      {
         Print("Position modified by profit floor stop. ticket=",
               IntegerToString((long)ticket),
               ", sl=", DoubleToString(target_sl, _Digits),
               ", tp=", DoubleToString(InpProfitFloorRemoveTakeProfit ? 0.0 : current_tp, _Digits));
      }
      else
      {
         Print("Failed to modify position by profit floor stop. ticket=",
               IntegerToString((long)ticket),
               ", retcode=", IntegerToString((int)trade.ResultRetcode()),
               ", description=", trade.ResultRetcodeDescription(),
               ", last_error=", GetLastError());
      }
   }

   return modify_attempted;
}

bool IsPositionProtectedByStop(const ENUM_POSITION_TYPE position_type,
                               const double open_price,
                               const double current_sl)
{
   if(current_sl <= 0.0)
      return false;

   if(position_type == POSITION_TYPE_BUY)
      return current_sl > open_price;

   if(position_type == POSITION_TYPE_SELL)
      return current_sl < open_price;

   return false;
}

int ExtractModelHoldBarsFromComment(const string comment)
{
   int marker = StringFind(comment, "-H");
   if(marker < 0)
      marker = StringFind(comment, " H");
   if(marker < 0)
      return 0;

   int pos = marker + 2;
   const int length = StringLen(comment);
   string digits = "";
   while(pos < length)
   {
      const int ch = StringGetCharacter(comment, pos);
      if(ch < '0' || ch > '9')
         break;

      digits += StringSubstr(comment, pos, 1);
      pos++;
   }

   if(StringLen(digits) <= 0)
      return 0;

   return (int)StringToInteger(digits);
}

bool IsModelHoldTimedOut(const datetime open_time,
                         const int hold_bars,
                         int &elapsed_seconds,
                         int &timeout_seconds)
{
   elapsed_seconds = 0;
   timeout_seconds = 0;

   if(!InpModelTimeExitEnabled || hold_bars <= 0 || open_time <= 0)
      return false;

   double effective_minutes = (double)hold_bars * MathMax(0.10, InpModelTimeExitGraceMultiplier);
   if(effective_minutes < (double)InpModelTimeExitMinMinutes)
      effective_minutes = (double)InpModelTimeExitMinMinutes;

   timeout_seconds = (int)MathRound(effective_minutes * 60.0);
   if(timeout_seconds <= 0)
      return false;

   elapsed_seconds = (int)(TimeCurrent() - open_time);
   return elapsed_seconds >= timeout_seconds;
}

bool ManageModelHoldTimeoutExits()
{
   if(!InpUseModelDirectTrading || !InpUseModelExecutionPlan || !InpModelTimeExitEnabled)
      return false;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return false;

   bool close_attempted = false;
   const int positions_total = PositionsTotal();
   for(int i = positions_total - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!IsManagedMagic(magic))
         continue;

      const ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_type != POSITION_TYPE_BUY && position_type != POSITION_TYPE_SELL)
         continue;

      const TradeSignal signal = (position_type == POSITION_TYPE_BUY ? SIGNAL_BUY : SIGNAL_SELL);
      double trail_start_atr = 0.0;
      double trail_distance_atr = 0.0;
      int hold_bars = 0;
      string reason = "";
      const int comment_hold_bars = ExtractModelHoldBarsFromComment(PositionGetString(POSITION_COMMENT));
      if(!GetModelPositionManagementPlan(signal,
                                         trail_start_atr,
                                         trail_distance_atr,
                                         hold_bars,
                                         reason))
      {
         if(comment_hold_bars <= 0)
            continue;

         hold_bars = comment_hold_bars;
         reason = "position_comment_hold_bars";
      }
      else if(comment_hold_bars > 0)
      {
         hold_bars = comment_hold_bars;
         reason += ", position_comment_hold_bars=" + IntegerToString(comment_hold_bars);
      }

      int elapsed_seconds = 0;
      int timeout_seconds = 0;
      const datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
      if(!IsModelHoldTimedOut(open_time, hold_bars, elapsed_seconds, timeout_seconds))
         continue;

      const double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      const double current_sl = PositionGetDouble(POSITION_SL);
      if(IsPositionProtectedByStop(position_type, open_price, current_sl))
         continue;

      const double profit = PositionGetDouble(POSITION_PROFIT);
      if(InpProfitFloorArmMoney > 0.0 && profit >= InpProfitFloorArmMoney)
         continue;

      double loss_points = 0.0;
      if(position_type == POSITION_TYPE_BUY)
         loss_points = (open_price - tick.bid) / _Point;
      else
         loss_points = (tick.ask - open_price) / _Point;
      if(loss_points < 0.0)
         loss_points = 0.0;

      Print("Closing managed position by model hold timeout. ticket=",
            IntegerToString((long)ticket),
            ", hold_bars=", IntegerToString(hold_bars),
            ", elapsed_sec=", IntegerToString(elapsed_seconds),
            ", timeout_sec=", IntegerToString(timeout_seconds),
            ", profit=", DoubleToString(profit, 2),
            ", reason=", reason);

      close_attempted = true;
      CloseManagedPositionByTicket(ticket, magic, "MODEL_HOLD_TIMEOUT", loss_points);
   }

   return close_attempted;
}

bool ManageModelTrailingStops()
{
   if(!InpUseModelDirectTrading || !InpUseModelExecutionPlan || !InpModelExecutionUseTrailing)
      return false;

   const double atr_value = GetIndicatorValue(atr_handle, 1);
   if(atr_value <= 0.0)
      return false;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return false;

   bool modify_attempted = false;
   const int positions_total = PositionsTotal();
   for(int i = positions_total - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!IsManagedMagic(magic))
         continue;

      const ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_type != POSITION_TYPE_BUY && position_type != POSITION_TYPE_SELL)
         continue;

      const TradeSignal signal = (position_type == POSITION_TYPE_BUY ? SIGNAL_BUY : SIGNAL_SELL);
      double trail_start_atr = 0.0;
      double trail_distance_atr = 0.0;
      int hold_bars = 0;
      string reason = "";
      if(!GetModelPositionManagementPlan(signal,
                                         trail_start_atr,
                                         trail_distance_atr,
                                         hold_bars,
                                         reason))
         continue;

      const double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      const double current_sl = PositionGetDouble(POSITION_SL);
      const double current_tp = PositionGetDouble(POSITION_TP);
      double profit_distance = 0.0;
      double target_sl = 0.0;
      const double stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      const double freeze_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
      const double min_distance = MathMax(MathMax(stops_level, freeze_level), _Point);

      if(position_type == POSITION_TYPE_BUY)
      {
         profit_distance = tick.bid - open_price;
         if(profit_distance < atr_value * trail_start_atr)
            continue;

         target_sl = NormalizePrice(tick.bid - (atr_value * trail_distance_atr));
         target_sl = MathMin(target_sl, NormalizePrice(tick.bid - min_distance));
      }
      else
      {
         profit_distance = open_price - tick.ask;
         if(profit_distance < atr_value * trail_start_atr)
            continue;

         target_sl = NormalizePrice(tick.ask + (atr_value * trail_distance_atr));
         target_sl = MathMax(target_sl, NormalizePrice(tick.ask + min_distance));
      }

      if(!IsProfitFloorStopImprovement(position_type, current_sl, target_sl) &&
         current_tp <= 0.0)
         continue;

      if(!IsProfitFloorStopImprovement(position_type, current_sl, target_sl))
         target_sl = current_sl;

      modify_attempted = true;
      Print("Model trailing stop update. ticket=", IntegerToString((long)ticket),
            ", magic=", IntegerToString((long)magic),
            ", profit_points=", DoubleToString(profit_distance / _Point, 1),
            ", trail_start_atr=", DoubleToString(trail_start_atr, 3),
            ", trail_distance_atr=", DoubleToString(trail_distance_atr, 3),
            ", hold_bars=", IntegerToString(hold_bars),
            ", current_sl=", DoubleToString(current_sl, _Digits),
            ", target_sl=", DoubleToString(target_sl, _Digits),
            ", current_tp=", DoubleToString(current_tp, _Digits),
            ", reason=", reason,
            ", dry_run=", BoolToText(InpDryRun));

      if(InpDryRun)
         continue;

      trade.SetExpertMagicNumber(magic);
      trade.SetDeviationInPoints(InpDeviationPoints);
      trade.SetTypeFillingBySymbol(_Symbol);
      if(trade.PositionModify(ticket, target_sl, 0.0))
      {
         Print("Position modified by model trailing stop. ticket=",
               IntegerToString((long)ticket),
               ", sl=", DoubleToString(target_sl, _Digits),
               ", tp=0.0");
      }
      else
      {
         Print("Failed to modify position by model trailing stop. ticket=",
               IntegerToString((long)ticket),
               ", retcode=", IntegerToString((int)trade.ResultRetcode()),
               ", description=", trade.ResultRetcodeDescription(),
               ", last_error=", GetLastError());
      }
   }

   return modify_attempted;
}

double ProfitFloorLockMoneyForProfit(const double profit)
{
   if(profit < InpProfitFloorArmMoney)
      return 0.0;

   const int completed_steps = (int)MathFloor((profit - InpProfitFloorArmMoney + 0.000001) /
                                              InpProfitFloorStepMoney);
   if(completed_steps <= 0)
      return InpProfitFloorLockMoney;

   return MathMax(InpProfitFloorLockMoney,
                  InpProfitFloorArmMoney + (completed_steps - 1) * InpProfitFloorStepMoney);
}

bool BuildProfitFloorStopPrice(const ENUM_POSITION_TYPE position_type,
                               const double open_price,
                               const double volume,
                               const double lock_money,
                               const MqlTick &tick,
                               double &target_sl)
{
   target_sl = 0.0;
   const double distance = ProfitMoneyToPriceDistance(lock_money, volume);
   if(open_price <= 0.0 || distance <= 0.0)
      return false;

   const double stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   const double freeze_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
   const double min_distance = MathMax(MathMax(stops_level, freeze_level), _Point);

   if(position_type == POSITION_TYPE_BUY)
   {
      target_sl = MathMin(open_price + distance, tick.bid - min_distance);
      target_sl = NormalizePrice(target_sl);
      return target_sl > open_price && target_sl < tick.bid;
   }

   if(position_type == POSITION_TYPE_SELL)
   {
      target_sl = MathMax(open_price - distance, tick.ask + min_distance);
      target_sl = NormalizePrice(target_sl);
      return target_sl < open_price && target_sl > tick.ask;
   }

   return false;
}

double ProfitMoneyToPriceDistance(const double money, const double volume)
{
   const double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   const double tick_value_profit = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_PROFIT);
   const double tick_value = tick_value_profit > 0.0
                             ? tick_value_profit
                             : SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(money <= 0.0 || volume <= 0.0 || tick_size <= 0.0 || tick_value <= 0.0)
      return 0.0;

   return NormalizePriceDistance(money * tick_size / (tick_value * volume));
}

bool IsProfitFloorStopImprovement(const ENUM_POSITION_TYPE position_type,
                                  const double current_sl,
                                  const double target_sl)
{
   if(target_sl <= 0.0)
      return false;
   if(current_sl <= 0.0)
      return true;
   if(position_type == POSITION_TYPE_BUY)
      return target_sl > current_sl + _Point;
   if(position_type == POSITION_TYPE_SELL)
      return target_sl < current_sl - _Point;
   return false;
}

bool ManageMaxLossStops()
{
   if(!InpEnableMaxLossStop)
      return false;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return false;

   bool action_attempted = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!IsManagedMagic(magic))
         continue;

      const ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_type != POSITION_TYPE_BUY && position_type != POSITION_TYPE_SELL)
         continue;

      const double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double loss_points = 0.0;
      if(position_type == POSITION_TYPE_BUY)
         loss_points = (open_price - tick.bid) / _Point;
      else
         loss_points = (tick.ask - open_price) / _Point;

      if(loss_points < InpMaxLossStopPoints)
      {
         if(EnsureMaxLossBrokerStop(ticket, magic, position_type, open_price, tick))
            action_attempted = true;
         continue;
      }

      action_attempted = true;
      CloseManagedPositionByTicket(ticket, magic, "max loss stop", loss_points);
   }

   return action_attempted;
}

bool EnsureMaxLossBrokerStop(const ulong ticket,
                             const ulong magic,
                             const ENUM_POSITION_TYPE position_type,
                             const double open_price,
                             const MqlTick &tick)
{
   if(ticket == 0 || !PositionSelectByTicket(ticket))
      return false;

   const double stop_distance = NormalizePriceDistance(InpMaxLossStopPoints * _Point);
   if(open_price <= 0.0 || stop_distance <= 0.0)
      return false;

   const double current_sl = PositionGetDouble(POSITION_SL);
   const double current_tp = PositionGetDouble(POSITION_TP);
   const double stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   const double freeze_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
   const double min_distance = MathMax(MathMax(stops_level, freeze_level), _Point);
   double target_sl = 0.0;

   if(position_type == POSITION_TYPE_BUY)
   {
      target_sl = NormalizePrice(open_price - stop_distance);
      if(target_sl >= tick.bid - min_distance)
         return false;
      if(current_sl > 0.0 && current_sl >= target_sl - _Point)
         return false;
   }
   else if(position_type == POSITION_TYPE_SELL)
   {
      target_sl = NormalizePrice(open_price + stop_distance);
      if(target_sl <= tick.ask + min_distance)
         return false;
      if(current_sl > 0.0 && current_sl <= target_sl + _Point)
         return false;
   }
   else
   {
      return false;
   }

   Print("Max loss broker SL update. ticket=", IntegerToString((long)ticket),
         ", magic=", IntegerToString((long)magic),
         ", open_price=", DoubleToString(open_price, _Digits),
         ", current_sl=", DoubleToString(current_sl, _Digits),
         ", target_sl=", DoubleToString(target_sl, _Digits),
         ", current_tp=", DoubleToString(current_tp, _Digits),
         ", max_loss_points=", IntegerToString(InpMaxLossStopPoints),
         ", dry_run=", BoolToText(InpDryRun));

   if(InpDryRun)
      return true;

   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   if(trade.PositionModify(ticket, target_sl, current_tp))
   {
      Print("Position modified by max loss broker SL. ticket=",
            IntegerToString((long)ticket),
            ", sl=", DoubleToString(target_sl, _Digits),
            ", tp=", DoubleToString(current_tp, _Digits));
   }
   else
   {
      Print("Failed to modify position by max loss broker SL. ticket=",
            IntegerToString((long)ticket),
            ", retcode=", IntegerToString((int)trade.ResultRetcode()),
            ", description=", trade.ResultRetcodeDescription(),
            ", last_error=", GetLastError());
   }

   return true;
}

bool CloseManagedPositionByTicket(const ulong ticket,
                                  const ulong magic,
                                  const string reason,
                                  const double loss_points)
{
   if(ticket == 0 || !PositionSelectByTicket(ticket))
      return true;

   Print("Closing managed position. ticket=", IntegerToString((long)ticket),
         ", reason=", reason,
         ", profit=", DoubleToString(PositionGetDouble(POSITION_PROFIT), 2),
         ", loss_points=", DoubleToString(loss_points, 1),
         ", max_loss_points=", IntegerToString(InpMaxLossStopPoints),
         ", volume=", DoubleToString(PositionGetDouble(POSITION_VOLUME), VolumeDigits()),
         ", type=", PositionTypeToText((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)),
         ", magic=", IntegerToString((long)magic),
         ", dry_run=", BoolToText(InpDryRun));

   if(InpDryRun)
      return true;

   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   if(trade.PositionClose(ticket))
      return true;

   Print("Failed to close managed position. ticket=", IntegerToString((long)ticket),
         ", retcode=", IntegerToString((int)trade.ResultRetcode()),
         ", description=", trade.ResultRetcodeDescription(),
         ", last_error=", GetLastError());
   return false;
}

string PositionTypeToText(const ENUM_POSITION_TYPE type)
{
   if(type == POSITION_TYPE_BUY)
      return "BUY";
   if(type == POSITION_TYPE_SELL)
      return "SELL";
   return "UNKNOWN";
}

bool IsManagedMagic(const ulong magic)
{
   return magic == InpLimitMagicNumber ||
          magic == InpStopMagicNumber ||
          magic == InpStopLimitMagicNumber ||
          magic == InpChartLineMagicNumber ||
          magic == InpModelDirectMagicNumber;
}

bool IsManagedPendingType(const ENUM_ORDER_TYPE type)
{
   return type == ORDER_TYPE_BUY_LIMIT ||
          type == ORDER_TYPE_SELL_LIMIT ||
          type == ORDER_TYPE_BUY_STOP ||
          type == ORDER_TYPE_SELL_STOP ||
          type == ORDER_TYPE_BUY_STOP_LIMIT ||
          type == ORDER_TYPE_SELL_STOP_LIMIT;
}

bool SubmitPlan(const PendingPlan &plan)
{
   if(InpDryRun && IsChartLineMode(plan.mode) && IsRepeatedChartLineDryRunPlan(plan))
      return true;

   LogPlan(InpDryRun ? "DRY-RUN" : "SUBMIT", plan);
   if(InpDryRun)
      return true;

   trade.SetExpertMagicNumber(plan.magic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   bool ok = false;
   if(plan.type == ORDER_TYPE_BUY_LIMIT)
      ok = trade.BuyLimit(plan.volume, plan.price, _Symbol, plan.sl, plan.tp,
                          ORDER_TIME_SPECIFIED, plan.expiration, plan.comment);
   else if(plan.type == ORDER_TYPE_SELL_LIMIT)
      ok = trade.SellLimit(plan.volume, plan.price, _Symbol, plan.sl, plan.tp,
                           ORDER_TIME_SPECIFIED, plan.expiration, plan.comment);
   else if(plan.type == ORDER_TYPE_BUY_STOP)
      ok = trade.BuyStop(plan.volume, plan.price, _Symbol, plan.sl, plan.tp,
                         ORDER_TIME_SPECIFIED, plan.expiration, plan.comment);
   else if(plan.type == ORDER_TYPE_SELL_STOP)
      ok = trade.SellStop(plan.volume, plan.price, _Symbol, plan.sl, plan.tp,
                          ORDER_TIME_SPECIFIED, plan.expiration, plan.comment);
   else if(plan.type == ORDER_TYPE_BUY_STOP_LIMIT ||
           plan.type == ORDER_TYPE_SELL_STOP_LIMIT)
      ok = SendStopLimitOrder(plan);

   if(!ok)
   {
      Print("Failed to submit ", plan.mode,
            ". type=", OrderTypeToText(plan.type),
            ", retcode=", IntegerToString((int)trade.ResultRetcode()),
            ", description=", trade.ResultRetcodeDescription(),
            ", last_error=", GetLastError());
      AppendSignalSnapshot("ERROR",
                           PlanSignal(plan),
                           plan.mode,
                           "ORDER_FAILED",
                           plan.volume,
                           plan.sl,
                           plan.tp,
                           0);
      return false;
   }

   const ulong order_ticket = trade.ResultOrder();
   Print("Pending order submitted. mode=", plan.mode,
         ", type=", OrderTypeToText(plan.type),
         ", ticket=", IntegerToString((long)order_ticket),
         ", volume=", DoubleToString(plan.volume, VolumeDigits()),
         ", price=", DoubleToString(plan.price, _Digits),
         ", stoplimit=", DoubleToString(plan.stoplimit, _Digits),
         ", sl=", DoubleToString(plan.sl, _Digits),
         ", tp=", DoubleToString(plan.tp, _Digits));
   AppendSignalSnapshot("ORDER",
                        PlanSignal(plan),
                        plan.mode,
                        "PLACED",
                        plan.volume,
                        plan.sl,
                        plan.tp,
                        order_ticket);
   SendTelegramPendingOrderNotification(plan, order_ticket);
   return true;
}

bool IsChartLineMode(const string mode)
{
   return StringFind(mode, "CHART_LINE_") == 0;
}

bool IsRepeatedChartLineDryRunPlan(const PendingPlan &plan)
{
   const string signature = ChartLinePlanSignature(plan);
   const int count = ArraySize(chart_line_dry_run_signatures);
   for(int i = 0; i < count; i++)
   {
      if(chart_line_dry_run_signatures[i] == signature)
         return true;
   }

   if(count >= 64)
      ArrayResize(chart_line_dry_run_signatures, 0);

   const int new_count = ArraySize(chart_line_dry_run_signatures) + 1;
   ArrayResize(chart_line_dry_run_signatures, new_count);
   chart_line_dry_run_signatures[new_count - 1] = signature;
   return false;
}

string ChartLinePlanSignature(const PendingPlan &plan)
{
   return plan.mode + "|" +
          OrderTypeToText(plan.type) + "|" +
          DoubleToString(plan.price, _Digits) + "|" +
          DoubleToString(plan.stoplimit, _Digits) + "|" +
          DoubleToString(plan.sl, _Digits) + "|" +
          DoubleToString(plan.tp, _Digits) + "|" +
          DoubleToString(plan.volume, VolumeDigits());
}

string ChartLineOrderComment(const string mode)
{
   return "BTC " + mode;
}

ulong ResolveTransactionMagic(const MqlTradeTransaction &trans,
                              const MqlTradeRequest &request)
{
   if(IsManagedMagic(request.magic))
      return request.magic;

   if(trans.deal > 0 && HistoryDealSelect(trans.deal))
   {
      const ulong deal_magic = (ulong)HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
      if(deal_magic > 0)
         return deal_magic;

      const ulong deal_order = (ulong)HistoryDealGetInteger(trans.deal, DEAL_ORDER);
      if(deal_order > 0 && HistoryOrderSelect(deal_order))
         return (ulong)HistoryOrderGetInteger(deal_order, ORDER_MAGIC);
   }

   if(trans.order > 0)
   {
      if(OrderSelect(trans.order))
         return (ulong)OrderGetInteger(ORDER_MAGIC);

      if(HistoryOrderSelect(trans.order))
         return (ulong)HistoryOrderGetInteger(trans.order, ORDER_MAGIC);
   }

   return 0;
}

void LogManagedDealDetails(const ulong deal_ticket)
{
   if(!HistoryDealSelect(deal_ticket))
      return;

   const ulong magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
   if(!IsManagedMagic(magic))
      return;

   const ulong order_ticket = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_ORDER);
   const ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
   const ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
   const double volume = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
   const double price = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
   const double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
   const double commission = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
   const double swap = HistoryDealGetDouble(deal_ticket, DEAL_SWAP);

   Print("Managed deal detail: deal=", IntegerToString((long)deal_ticket),
         ", order=", IntegerToString((long)order_ticket),
         ", magic=", IntegerToString((long)magic),
         ", deal_type=", EnumToString(deal_type),
         ", entry=", EnumToString(deal_entry),
         ", volume=", DoubleToString(volume, VolumeDigits()),
         ", price=", DoubleToString(price, _Digits),
         ", profit=", DoubleToString(profit, 2),
         ", commission=", DoubleToString(commission, 2),
         ", swap=", DoubleToString(swap, 2));
}

TradeSignal PlanSignal(const PendingPlan &plan)
{
   if(IsBuyType(plan.type))
      return SIGNAL_BUY;
   return SIGNAL_SELL;
}

double GetIndicatorValue(const int handle, const int shift)
{
   if(handle == INVALID_HANDLE)
      return 0.0;

   double values[];
   ArrayResize(values, 1);
   ArraySetAsSeries(values, true);
   if(CopyBuffer(handle, 0, shift, 1, values) < 1)
      return 0.0;

   return values[0];
}

void AppendSignalSnapshot(const string action,
                          const TradeSignal signal,
                          const string setup,
                          const string reason,
                          const double volume,
                          const double sl,
                          const double tp,
                          const ulong order_ticket)
{
   if(signal_log_file_name == "")
      return;

   bool exists = FileIsExist(signal_log_file_name);
   int handle = FileOpen(signal_log_file_name,
                         FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE,
                         '\t');
   if(handle == INVALID_HANDLE)
   {
      Print("Failed to open signal log file: ", signal_log_file_name);
      return;
   }

   if(!exists || FileSize(handle) == 0)
   {
      FileWrite(handle,
                "time",
                "symbol",
                "signal_tf",
                "trend_tf",
                "action",
                "direction",
                "setup",
                "reason",
                "bid",
                "ask",
                "spread_points",
                "ema20",
                "ema50",
                "htf_ema50",
                "htf_ema200",
                "ema50_slope",
                "rsi",
                "atr",
                "ma_spread_atr",
                "slow_slope_atr",
                "htf_bias",
                "calendar_blocked",
                "volume",
                "sl",
                "tp",
                "order_ticket",
                "quant_score",
                "quant_opposite_score",
                "quant_factors",
                "model_source_model",
                "model_run_id",
                "model_action",
                "model_probability",
                "model_confidence",
                "model_net_expectancy_atr",
                "model_rule_score",
                "model_rule_samples",
                "model_candle_time",
                "model_frequency_bias",
                "model_direction_bias");
   }

   FileSeek(handle, 0, SEEK_END);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      point = _Point;
   double spread_points = 0.0;
   if(point > 0.0)
      spread_points = (ask - bid) / point;

   const double fast_ma = GetIndicatorValue(fast_ma_handle, 1);
   const double slow_ma = GetIndicatorValue(slow_ma_handle, 1);
   const double slow_ma_previous = GetIndicatorValue(slow_ma_handle, 2);
   const double rsi_value = GetIndicatorValue(rsi_handle, 1);
   const double atr_value = GetIndicatorValue(atr_handle, 1);
   const double htf_slow_ma = GetIndicatorValue(trend_slow_ma_handle, 1);
   const double htf_baseline_ma = GetIndicatorValue(trend_baseline_ma_handle, 1);

   const double ema_slope = slow_ma - slow_ma_previous;
   double ma_spread_atr = 0.0;
   double slow_slope_atr = 0.0;
   if(atr_value > 0.0)
   {
      ma_spread_atr = MathAbs(fast_ma - slow_ma) / atr_value;
      slow_slope_atr = MathAbs(ema_slope) / atr_value;
   }

   string model_source_model = "";
   string model_run_id = "";
   string model_action = "";
   string model_candle_time = "";
   string model_frequency_bias = "";
   string model_direction_bias = "";
   double model_probability = 0.0;
   double model_confidence = 0.0;
   double model_net_expectancy_atr = 0.0;
   double model_rule_score = 0.0;
   int model_rule_samples = 0;
   if(setup == "MODEL_DIRECT" || InpUseModelDirectTrading)
      GetModelSignalLogFields(model_source_model,
                              model_run_id,
                              model_action,
                              model_candle_time,
                              model_frequency_bias,
                              model_direction_bias,
                              model_probability,
                              model_confidence,
                              model_net_expectancy_atr,
                              model_rule_score,
                              model_rule_samples);

   FileWrite(handle,
             TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
             _Symbol,
             EnumToString(InpSignalTimeframe),
             EnumToString(InpTrendTimeframe),
             action,
             TradeSignalToText(signal),
             setup,
             reason,
             DoubleToString(bid, _Digits),
             DoubleToString(ask, _Digits),
             DoubleToString(spread_points, 1),
             DoubleToString(fast_ma, _Digits),
             DoubleToString(slow_ma, _Digits),
             DoubleToString(htf_slow_ma, _Digits),
             DoubleToString(htf_baseline_ma, _Digits),
             DoubleToString(ema_slope, _Digits),
             DoubleToString(rsi_value, 2),
             DoubleToString(atr_value, _Digits),
             DoubleToString(ma_spread_atr, 4),
             DoubleToString(slow_slope_atr, 4),
             TradeSignalToText(GetHigherTimeframeBias()),
             "false",
             DoubleToString(volume, VolumeDigits()),
             DoubleToString(sl, _Digits),
             DoubleToString(tp, _Digits),
             UInt64ToText(order_ticket),
             "",
             "",
             "",
             model_source_model,
             model_run_id,
             model_action,
             DoubleToString(model_probability, 6),
             DoubleToString(model_confidence, 6),
             DoubleToString(model_net_expectancy_atr, 6),
             DoubleToString(model_rule_score, 6),
             IntegerToString(model_rule_samples),
             model_candle_time,
             model_frequency_bias,
             model_direction_bias);

   FileClose(handle);
}

void AppendDealLog(const ulong deal_ticket)
{
   if(log_file_name == "")
      return;
   if(!HistoryDealSelect(deal_ticket))
      return;

   const ulong magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
   if(!IsManagedMagic(magic))
      return;

   bool exists = FileIsExist(log_file_name);
   int handle = FileOpen(log_file_name,
                         FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE,
                         '\t');
   if(handle == INVALID_HANDLE)
   {
      Print("Failed to open deal log file: ", log_file_name);
      return;
   }

   if(!exists || FileSize(handle) == 0)
   {
      FileWrite(handle,
                "deal_id",
                "time",
                "symbol",
                "entry",
                "type",
                "volume",
                "price",
                "profit",
                "commission",
                "swap",
                "magic",
                "position_id",
                "comment",
                "reason");
   }

   FileSeek(handle, 0, SEEK_END);

   const datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
   FileWrite(handle,
             UInt64ToText(deal_ticket),
             TimeToString(deal_time, TIME_DATE | TIME_SECONDS),
             HistoryDealGetString(deal_ticket, DEAL_SYMBOL),
             DealEntryToText((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY)),
             DealTypeToText((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE)),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_VOLUME), VolumeDigits()),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_PRICE), _Digits),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_PROFIT), 2),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION), 2),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_SWAP), 2),
             IntegerToString((int)magic),
             UInt64ToText((ulong)HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID)),
             HistoryDealGetString(deal_ticket, DEAL_COMMENT),
             DealReasonToText((ENUM_DEAL_REASON)HistoryDealGetInteger(deal_ticket, DEAL_REASON)));

   FileClose(handle);
}

string DealEntryToText(const ENUM_DEAL_ENTRY entry)
{
   if(entry == DEAL_ENTRY_IN)
      return "IN";
   if(entry == DEAL_ENTRY_OUT)
      return "OUT";
   if(entry == DEAL_ENTRY_INOUT)
      return "INOUT";
   if(entry == DEAL_ENTRY_OUT_BY)
      return "OUT_BY";
   return EnumToString(entry);
}

string DealTypeToText(const ENUM_DEAL_TYPE deal_type)
{
   if(deal_type == DEAL_TYPE_BUY)
      return "BUY";
   if(deal_type == DEAL_TYPE_SELL)
      return "SELL";
   return EnumToString(deal_type);
}

string DealReasonToText(const ENUM_DEAL_REASON reason)
{
   if(reason == DEAL_REASON_CLIENT)
      return "CLIENT";
   if(reason == DEAL_REASON_MOBILE)
      return "MOBILE";
   if(reason == DEAL_REASON_WEB)
      return "WEB";
   if(reason == DEAL_REASON_EXPERT)
      return "EXPERT";
   if(reason == DEAL_REASON_SL)
      return "SL";
   if(reason == DEAL_REASON_TP)
      return "TP";
   if(reason == DEAL_REASON_SO)
      return "SO";
   return EnumToString(reason);
}

string UInt64ToText(const ulong value)
{
   return StringFormat("%I64u", value);
}

bool SendStopLimitOrder(const PendingPlan &plan)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_PENDING;
   request.symbol = _Symbol;
   request.magic = plan.magic;
   request.volume = plan.volume;
   request.type = plan.type;
   request.price = plan.price;
   request.stoplimit = plan.stoplimit;
   request.sl = plan.sl;
   request.tp = plan.tp;
   request.deviation = InpDeviationPoints;
   request.type_time = ORDER_TIME_SPECIFIED;
   request.expiration = plan.expiration;
   request.type_filling = ResolveFillingMode();
   request.comment = plan.comment;

   const bool ok = OrderSend(request, result);
   if(!ok)
   {
      Print("Stop-limit OrderSend failed. retcode=", IntegerToString((int)result.retcode),
            ", comment=", result.comment,
            ", last_error=", GetLastError());
      return false;
   }

   return true;
}

ENUM_ORDER_TYPE_FILLING ResolveFillingMode()
{
   const long filling_mode = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling_mode & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   if((filling_mode & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
}

datetime BuildExpirationTime()
{
   return BuildExpirationTimeForTimeframe(InpOrderExpiryBars, InpSignalTimeframe);
}

datetime BuildChartLineExpirationTime()
{
   return BuildExpirationTimeForTimeframe(InpChartLineExpiryBars, InpChartLineTimeframe);
}

datetime BuildExpirationTimeForTimeframe(const int expiry_bars,
                                         const ENUM_TIMEFRAMES timeframe)
{
   const int period_seconds = PeriodSeconds(timeframe);
   const int expiry_seconds = MathMax(period_seconds, 60) * MathMax(expiry_bars, 1);
   return TimeCurrent() + expiry_seconds;
}

double PlanFillPrice(const PendingPlan &plan)
{
   if(plan.type == ORDER_TYPE_BUY_STOP_LIMIT || plan.type == ORDER_TYPE_SELL_STOP_LIMIT)
      return plan.stoplimit;
   return plan.price;
}

bool IsBuyType(const ENUM_ORDER_TYPE type)
{
   return type == ORDER_TYPE_BUY_LIMIT ||
          type == ORDER_TYPE_BUY_STOP ||
          type == ORDER_TYPE_BUY_STOP_LIMIT;
}

double NormalizePrice(const double price)
{
   return NormalizeDouble(price, _Digits);
}

double NormalizePriceDistance(const double distance)
{
   return MathMax(NormalizeDouble(distance, _Digits), _Point);
}

void LogInvalidPrice(const PendingPlan &plan, const string reason)
{
   if(!InpVerboseLogs)
      return;

   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   Print("Skipping ", plan.mode,
         ": ", reason,
         ". type=", OrderTypeToText(plan.type),
         ", bid=", DoubleToString(tick.bid, _Digits),
         ", ask=", DoubleToString(tick.ask, _Digits),
         ", price=", DoubleToString(plan.price, _Digits),
         ", stoplimit=", DoubleToString(plan.stoplimit, _Digits),
         ", sl=", DoubleToString(plan.sl, _Digits),
         ", tp=", DoubleToString(plan.tp, _Digits));
}

void LogPlan(const string action, const PendingPlan &plan)
{
   Print(action, " ", plan.mode,
         ": type=", OrderTypeToText(plan.type),
         ", magic=", IntegerToString((long)plan.magic),
         ", volume=", DoubleToString(plan.volume, VolumeDigits()),
         ", price=", DoubleToString(plan.price, _Digits),
         ", stoplimit=", DoubleToString(plan.stoplimit, _Digits),
         ", sl=", DoubleToString(plan.sl, _Digits),
         ", tp=", DoubleToString(plan.tp, _Digits),
         ", expiry=", TimeToString(plan.expiration, TIME_DATE | TIME_MINUTES),
         ", risk_percent=", DoubleToString(plan.risk_percent, 3),
         ", min_volume_fallback=", BoolToText(plan.used_min_volume_fallback));
}

void LogVerbose(const string message)
{
   if(InpVerboseLogs)
      Print(message);
}

void PrintTradingEnvironment()
{
   const long trade_mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   const long order_mode = SymbolInfoInteger(_Symbol, SYMBOL_ORDER_MODE);
   const double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   const double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   const double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   const double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   const long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);

   Print("Trading environment: trade_mode=", IntegerToString(trade_mode),
         ", order_mode=", IntegerToString(order_mode),
         ", leverage=1:", IntegerToString(leverage),
         ", contract_size=", DoubleToString(contract_size, 2),
         ", tick_size=", DoubleToString(tick_size, _Digits),
         ", tick_value=", DoubleToString(tick_value, 8),
         ", min_volume=", DoubleToString(min_volume, VolumeDigits()),
         ", volume_step=", DoubleToString(volume_step, VolumeDigits()));
}

string PriceToText(const double price)
{
   if(price <= 0.0)
      return "-";

   return DoubleToString(price, _Digits);
}

string UrlEncode(const string value)
{
   char bytes[];
   int count = StringToCharArray(value, bytes, 0, WHOLE_ARRAY, CP_UTF8);
   string encoded = "";

   for(int i = 0; i < count; ++i)
   {
      int b = (int)bytes[i];
      if(b == 0 && i == count - 1)
         break;
      if(b < 0)
         b += 256;

      bool safe = (b >= 'A' && b <= 'Z') ||
                  (b >= 'a' && b <= 'z') ||
                  (b >= '0' && b <= '9') ||
                  b == '-' || b == '_' || b == '.' || b == '~';
      if(safe)
         encoded += CharToString((uchar)b);
      else
         encoded += StringFormat("%%%02X", b);
   }

   return encoded;
}

bool ParseTelegramConfigLine(string line, string &key, string &value)
{
   StringTrimLeft(line);
   StringTrimRight(line);
   if(line == "")
      return false;

   ushort first_char = StringGetCharacter(line, 0);
   if(first_char == '#' || first_char == ';')
      return false;

   int separator = StringFind(line, ":");
   int equals_separator = StringFind(line, "=");
   if(separator < 0 || (equals_separator >= 0 && equals_separator < separator))
      separator = equals_separator;
   if(separator <= 0)
      return false;

   key = StringSubstr(line, 0, separator);
   value = StringSubstr(line, separator + 1);
   StringTrimLeft(key);
   StringTrimRight(key);
   StringTrimLeft(value);
   StringTrimRight(value);
   StringToLower(key);

   return key != "" && value != "";
}

void LoadTelegramSettings()
{
   telegram_api_url = InpTelegramApiURL;
   telegram_env = InpTelegramEnv;
   telegram_bot_token = InpTelegramBotToken;
   telegram_chat_id = InpTelegramChatID;

   if(InpTelegramConfigFile != "")
   {
      ResetLastError();
      int handle = FileOpen(InpTelegramConfigFile,
                            FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE);
      if(handle == INVALID_HANDLE)
      {
         LogVerbose("Telegram config file not found or unreadable: " + InpTelegramConfigFile +
                    ". error=" + IntegerToString(GetLastError()));
      }
      else
      {
         while(!FileIsEnding(handle))
         {
            string line = FileReadString(handle);
            string key = "";
            string value = "";
            if(!ParseTelegramConfigLine(line, key, value))
               continue;

            if((key == "url" || key == "api_url" || key == "base_url") && telegram_api_url == "")
               telegram_api_url = value;
            else if((key == "env" || key == "environment" || key == "account_env") && telegram_env == "")
               telegram_env = value;
            else if((key == "token" || key == "bot_token" || key == "telegram_token") && telegram_bot_token == "")
               telegram_bot_token = value;
            else if((key == "chat_id" || key == "chatid") && telegram_chat_id == "")
               telegram_chat_id = value;
         }
         FileClose(handle);
      }
   }

   if(telegram_api_url == "")
      telegram_api_url = "https://api.telegram.org";

   LogVerbose("Telegram settings loaded: config_file=" + InpTelegramConfigFile +
              ", env=" + (telegram_env == "" ? "-" : telegram_env) +
              ", token=" + (telegram_bot_token == "" ? "MISSING" : "SET") +
              ", chat_id=" + (telegram_chat_id == "" ? "MISSING" : "SET"));
}

string TelegramBaseURL()
{
   string base_url = telegram_api_url;
   StringTrimLeft(base_url);
   StringTrimRight(base_url);
   if(base_url == "")
      base_url = "https://api.telegram.org";

   while(StringLen(base_url) > 0 && StringSubstr(base_url, StringLen(base_url) - 1, 1) == "/")
      base_url = StringSubstr(base_url, 0, StringLen(base_url) - 1);

   return base_url;
}

bool TelegramPostMessage(const string message)
{
   if(!InpTelegramEnabled)
      return false;

   if(telegram_bot_token == "" || telegram_chat_id == "")
   {
      LogVerbose("Telegram notification skipped: missing bot token or chat id.");
      return false;
   }

   string url = TelegramBaseURL() + "/bot" + telegram_bot_token + "/sendMessage";
   string body = "chat_id=" + UrlEncode(telegram_chat_id) +
                 "&text=" + UrlEncode(message) +
                 "&disable_web_page_preview=true";
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   char data[];
   int data_len = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
   if(data_len > 0)
      ArrayResize(data, data_len - 1);

   char result[];
   string result_headers = "";
   int timeout = InpTelegramTimeoutMs;
   if(timeout < 1000)
      timeout = 1000;

   ResetLastError();
   int status = WebRequest("POST", url, headers, timeout, data, result, result_headers);
   if(status == -1)
   {
      Print("Telegram notification failed: WebRequest error=", GetLastError(),
            ". Trading is unaffected. Allow https://api.telegram.org in MT5 WebRequest settings if needed.");
      return false;
   }

   if(status < 200 || status >= 300)
   {
      Print("Telegram notification failed: HTTP status=", status,
            ". Trading is unaffected. Response=",
            CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8));
      return false;
   }

   LogVerbose("Telegram notification sent.");
   return true;
}

string TelegramHeader(const string action)
{
   string env = telegram_env;
   if(env == "")
      env = "-";

   return "[" + ConfiguredSymbol() + " pending] " + action + "\n" +
          "env: " + env + "\n" +
          "symbol: " + _Symbol + "\n";
}

void SendTelegramModelDirectNotification(const TradeSignal signal,
                                         const double volume,
                                         const double result_price,
                                         const double sl,
                                         const double tp,
                                         const double risk_distance,
                                         const string model_reason)
{
   if(!InpTelegramEnabled)
      return;

   string price = PriceToText(result_price);
   if(price == "-")
      price = PriceToText(trade.RequestPrice());

   string message = TelegramHeader("model direct opened") +
                    "direction: " + TradeSignalToText(signal) + "\n" +
                    "volume: " + DoubleToString(volume, VolumeDigits()) + "\n" +
                    "price: " + price + "\n" +
                    "sl: " + PriceToText(sl) + "\n" +
                    "tp: " + PriceToText(tp) + "\n" +
                    "risk_distance: " + DoubleToString(risk_distance, _Digits) + "\n" +
                    "model: " + model_reason + "\n" +
                    "order: " + IntegerToString((long)trade.ResultOrder()) + "\n" +
                    "deal: " + IntegerToString((long)trade.ResultDeal()) + "\n" +
                    "account: " + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) + "\n" +
                    "server: " + AccountInfoString(ACCOUNT_SERVER) + "\n" +
                    "time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);

   TelegramPostMessage(message);
}

void SendTelegramPendingOrderNotification(const PendingPlan &plan,
                                          const ulong order_ticket)
{
   if(!InpTelegramEnabled)
      return;

   string message = TelegramHeader("pending order placed") +
                    "mode: " + plan.mode + "\n" +
                    "type: " + OrderTypeToText(plan.type) + "\n" +
                    "volume: " + DoubleToString(plan.volume, VolumeDigits()) + "\n" +
                    "price: " + PriceToText(plan.price) + "\n" +
                    "stoplimit: " + PriceToText(plan.stoplimit) + "\n" +
                    "sl: " + PriceToText(plan.sl) + "\n" +
                    "tp: " + PriceToText(plan.tp) + "\n" +
                    "risk_percent: " + DoubleToString(plan.risk_percent, 3) + "\n" +
                    "order: " + IntegerToString((long)order_ticket) + "\n" +
                    "magic: " + IntegerToString((long)plan.magic) + "\n" +
                    "account: " + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) + "\n" +
                    "server: " + AccountInfoString(ACCOUNT_SERVER) + "\n" +
                    "time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);

   TelegramPostMessage(message);
}

void SendTelegramDealNotification(const ulong deal_ticket)
{
   if(!InpTelegramEnabled || deal_ticket == 0)
      return;
   if(!HistoryDealSelect(deal_ticket))
      return;

   const ulong magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
   if(!IsManagedMagic(magic) || magic == InpModelDirectMagicNumber)
      return;

   const ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
   if(deal_entry != DEAL_ENTRY_IN && deal_entry != DEAL_ENTRY_INOUT)
      return;

   const ulong order_ticket = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_ORDER);
   const string comment = HistoryDealGetString(deal_ticket, DEAL_COMMENT);
   string message = TelegramHeader("pending order filled") +
                    "entry: " + DealEntryToText(deal_entry) + "\n" +
                    "type: " + DealTypeToText((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE)) + "\n" +
                    "volume: " + DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_VOLUME), VolumeDigits()) + "\n" +
                    "price: " + PriceToText(HistoryDealGetDouble(deal_ticket, DEAL_PRICE)) + "\n" +
                    "profit: " + DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_PROFIT), 2) + "\n" +
                    "order: " + IntegerToString((long)order_ticket) + "\n" +
                    "deal: " + IntegerToString((long)deal_ticket) + "\n" +
                    "magic: " + IntegerToString((long)magic) + "\n" +
                    "comment: " + comment + "\n" +
                    "account: " + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) + "\n" +
                    "server: " + AccountInfoString(ACCOUNT_SERVER) + "\n" +
                    "time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);

   TelegramPostMessage(message);
}

string BoolToText(const bool value)
{
   return value ? "true" : "false";
}

string OrderTypeToText(const ENUM_ORDER_TYPE type)
{
   if(type == ORDER_TYPE_BUY_LIMIT)
      return "BUY_LIMIT";
   if(type == ORDER_TYPE_SELL_LIMIT)
      return "SELL_LIMIT";
   if(type == ORDER_TYPE_BUY_STOP)
      return "BUY_STOP";
   if(type == ORDER_TYPE_SELL_STOP)
      return "SELL_STOP";
   if(type == ORDER_TYPE_BUY_STOP_LIMIT)
      return "BUY_STOP_LIMIT";
   if(type == ORDER_TYPE_SELL_STOP_LIMIT)
      return "SELL_STOP_LIMIT";
   return EnumToString(type);
}

void ReleaseHandle(int &handle)
{
   if(handle != INVALID_HANDLE)
   {
      IndicatorRelease(handle);
      handle = INVALID_HANDLE;
   }
}

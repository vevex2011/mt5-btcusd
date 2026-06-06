#property strict
#property version   "1.00"
#property description "BTCUSD Windows real-account light-model EA with strict small-account risk guards."

#include <Trade/Trade.mqh>

input string          InpTargetSymbol         = "BTCUSD";
input bool            InpEnforceTargetSymbol  = true;
input ENUM_TIMEFRAMES InpSignalTimeframe      = PERIOD_M1;
input bool            InpUseHigherTimeframeTrendFilter = false;
input ENUM_TIMEFRAMES InpTrendFilterTimeframe = PERIOD_H1;
input int             InpTrendConfirmBars    = 3;
input int             InpTrendBaselineMAPeriod = 200;
input double          InpMinTrendSpreadATR   = 0.00;
input double          InpMinSlowMASlopeATR   = 0.00;
input bool            InpEnableFirstLegEntry = true;
input int             InpFirstLegBreakoutLookback = 2;
input double          InpFirstLegLongRSIMin  = 45.0;
input double          InpFirstLegLongRSIMax  = 65.0;
input double          InpFirstLegShortRSIMin = 35.0;
input double          InpFirstLegShortRSIMax = 55.0;
input double          InpPullbackLongRSIMin  = 50.0;
input double          InpPullbackLongRSIMax  = 72.0;
input double          InpPullbackShortRSIMin = 28.0;
input double          InpPullbackShortRSIMax = 50.0;
input bool            InpRequireSecondPullbackConfirmation = true;
input double          InpTrendATRStopMultiplier = 0.90;
input bool            InpEnableContinuationEntry = false;
input int             InpContinuationBreakoutLookback = 3;
input double          InpContinuationLongRSIMin = 58.0;
input double          InpContinuationLongRSIMax = 78.0;
input double          InpContinuationShortRSIMin = 24.0;
input double          InpContinuationShortRSIMax = 42.0;
input bool            InpAllowAddOnEntry     = false;
input int             InpMaxPositionsPerDirection = 1;
input double          InpAddOnMinProfitR     = 0.80;
input int             InpStopLossCooldownBars = 4;
input ulong           InpMagicNumber          = 2026052601;
input bool            InpWindowsCoexistenceMode = true;
input ulong           InpPeerPendingModelMagicNumber = 2026052625;
input int             InpMaxCombinedBTCPositions = 2;
input double          InpMaxCombinedBTCVolume = 0.02;
input bool            InpBlockOppositeCoexistencePositions = true;
input double          InpRiskPerTradePercent  = 0.10;
input double          InpMaxVolumePerTrade    = 0.01;
input double          InpMinEquityToTrade     = 80.00;
input double          InpMaxDailyLossMoney    = 3.00;
input int             InpMaxConsecutiveLosses = 2;
input int             InpFastMAPeriod         = 20;
input int             InpSlowMAPeriod         = 50;
input int             InpRSIPeriod            = 14;
input int             InpATRPeriod            = 14;
input double          InpStopLossATR          = 1.20;
input double          InpTakeProfitRewardRisk = 1.50;
input double          InpBreakEvenTriggerR    = 1.00;
input double          InpTrailStartR          = 1.30;
input double          InpTrailDistanceR       = 0.80;
input double          InpProfitLockTriggerR   = 0.50;
input double          InpProfitLockAmountR    = 0.10;
input bool            InpRemoveTakeProfitOnLock = true;
input double          InpRemoveTakeProfitTriggerR = 1.00;
input int             InpMaxSpreadPoints      = 5000;
input double          InpMaxSpreadATR         = 0.08;
input bool            InpUseTradingHours      = false;
input int             InpTradeStartHour       = 8;
input int             InpTradeEndHour         = 22;
input double          InpMaxDailyLossPercent  = 0.00;
input bool            InpUseEconomicCalendarFilter = false;
input string          InpCalendarCurrencies   = "USD";
input ENUM_CALENDAR_EVENT_IMPORTANCE InpCalendarMinImportance = CALENDAR_IMPORTANCE_HIGH;
input int             InpCalendarPreEventMinutes = 90;
input int             InpCalendarPostEventMinutes = 45;
input int             InpCalendarRefreshSeconds = 300;
input string          InpCalendarCachePrefix = "CodexCalendarCache.USD";
input int             InpCalendarCacheMaxAgeSeconds = 900;
input int             InpCalendarCacheMaxEvents = 64;
input bool            InpBlockOnCalendarError = false;
input bool            InpAllowLong            = true;
input bool            InpAllowShort           = true;
input bool            InpUseMinVolumeFallback = true;
input double          InpMaxFallbackRiskPercent = 5.00;
input bool            InpShowIndicators       = false;
input string          InpLogFolder            = "codex-mt5-btc-windows-ea";
input bool            InpVerboseLogs          = true;
input bool            InpTelegramEnabled      = true;
input string          InpTelegramConfigFile   = "telegram.info";
input string          InpTelegramApiURL       = "";
input string          InpTelegramEnv          = "";
input string          InpTelegramBotToken     = "";
input string          InpTelegramChatID       = "";
input int             InpTelegramTimeoutMs    = 5000;
input bool            InpUseModelRecommendationFilter = true;
input string          InpModelRecommendationFile = "codex-edge-model\\edge_recommendations.json";
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
input bool            InpUseModelDirectTrading = true;
input bool            InpModelDirectPreferDeepModel = true;
input bool            InpModelDirectRequireDeepModel = true;
input double          InpDeepModelMinProbability = 0.62;
input double          InpDeepModelMinConfidence = 0.10;
input bool            InpModelDirectUseTopRule = false;
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

enum TradeSignal
{
   SIGNAL_NONE = 0,
   SIGNAL_BUY  = 1,
   SIGNAL_SELL = -1
};

#include "CodexModelRecommendations.mqh"

CTrade   trade;
int      fast_ma_handle = INVALID_HANDLE;
int      slow_ma_handle = INVALID_HANDLE;
int      trend_slow_ma_handle = INVALID_HANDLE;
int      trend_baseline_ma_handle = INVALID_HANDLE;
int      trend_atr_handle = INVALID_HANDLE;
int      rsi_handle     = INVALID_HANDLE;
int      atr_handle     = INVALID_HANDLE;
int      visual_fast_ma_handle = INVALID_HANDLE;
int      visual_slow_ma_handle = INVALID_HANDLE;
int      visual_baseline_ma_handle = INVALID_HANDLE;
int      visual_rsi_handle     = INVALID_HANDLE;
int      visual_atr_handle     = INVALID_HANDLE;
string   visual_fast_ma_name   = "";
string   visual_slow_ma_name   = "";
string   visual_baseline_ma_name = "";
string   visual_rsi_name       = "";
string   visual_atr_name       = "";
int      visual_rsi_window     = -1;
int      visual_atr_window     = -1;
datetime last_bar_time  = 0;
string   log_file_name  = "";
string   signal_log_file_name = "";
bool     last_signal_is_first_leg = false;
string   last_signal_setup = "PULLBACK";
string   last_signal_skip_reason = "NO_SIGNAL";
datetime last_long_stop_loss_time = 0;
datetime last_short_stop_loss_time = 0;
string   telegram_api_url = "";
string   telegram_env = "";
string   telegram_bot_token = "";
string   telegram_chat_id = "";

string ConfiguredSymbol()
{
   if(InpTargetSymbol == "")
      return(_Symbol);

   return(InpTargetSymbol);
}

bool IsAllowedChartSymbol()
{
   if(!InpEnforceTargetSymbol || InpTargetSymbol == "")
      return(true);

   if(StringLen(_Symbol) < StringLen(InpTargetSymbol))
      return(false);

   return(StringSubstr(_Symbol, 0, StringLen(InpTargetSymbol)) == InpTargetSymbol);
}

int OnInit()
{
   if(!IsAllowedChartSymbol())
   {
      Print("CodexTrendPullbackEA-", ConfiguredSymbol(),
            " can only run on symbols beginning with ", InpTargetSymbol,
            ". Current chart: ", _Symbol);
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpUseHigherTimeframeTrendFilter)
   {
      if(InpTrendConfirmBars < 2)
      {
         Print("Trend filter confirmation bars must be at least 2.");
         return(INIT_PARAMETERS_INCORRECT);
      }

      if((int)InpTrendFilterTimeframe <= (int)InpSignalTimeframe)
      {
         Print("Trend filter timeframe must be higher than signal timeframe.");
         return(INIT_PARAMETERS_INCORRECT);
      }

      if(InpTrendBaselineMAPeriod <= InpSlowMAPeriod)
      {
         Print("Trend baseline MA period must be greater than the slow MA period.");
         return(INIT_PARAMETERS_INCORRECT);
      }

      if(InpTrendATRStopMultiplier <= 0.0)
      {
         Print("Trend ATR stop multiplier must be positive.");
         return(INIT_PARAMETERS_INCORRECT);
      }
   }

   if(InpFastMAPeriod <= 1 || InpSlowMAPeriod <= InpFastMAPeriod)
   {
      Print("Invalid MA settings.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpATRPeriod <= 1 || InpRSIPeriod <= 1 || InpRiskPerTradePercent <= 0.0)
   {
      Print("Invalid risk or indicator settings.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpMaxVolumePerTrade < 0.0 ||
      InpMinEquityToTrade < 0.0 ||
      InpMaxDailyLossMoney < 0.0 ||
      InpMaxConsecutiveLosses < 0 ||
      InpMaxCombinedBTCPositions < 1 ||
      InpMaxCombinedBTCVolume < 0.0)
   {
      Print("Invalid small-account guard settings.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpFirstLegBreakoutLookback < 2)
   {
      Print("First leg breakout lookback must be at least 2.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpFirstLegLongRSIMin > InpFirstLegLongRSIMax ||
      InpFirstLegShortRSIMin > InpFirstLegShortRSIMax)
   {
      Print("Invalid first leg RSI ranges.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpPullbackLongRSIMin > InpPullbackLongRSIMax ||
      InpPullbackShortRSIMin > InpPullbackShortRSIMax)
   {
      Print("Invalid pullback RSI ranges.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpTrendATRStopMultiplier <= 0.0)
   {
      Print("Trend ATR stop multiplier must be positive.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpTakeProfitRewardRisk <= 0.0 ||
      InpBreakEvenTriggerR <= 0.0 ||
      InpTrailStartR <= 0.0 ||
      InpTrailDistanceR <= 0.0)
   {
      Print("Invalid R-based exit settings.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpMinTrendSpreadATR < 0.0 || InpMinSlowMASlopeATR < 0.0 || InpMaxSpreadATR < 0.0)
   {
      Print("Trend spread/slope/spread ATR thresholds must be non-negative.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpMaxPositionsPerDirection < 1)
   {
      Print("Max positions per direction must be at least 1.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpAddOnMinProfitR < 0.0)
   {
      Print("Add-on profit R threshold must be non-negative.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpStopLossCooldownBars < 0)
   {
      Print("Stop-loss cooldown bars must be non-negative.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpCalendarPreEventMinutes < 0 || InpCalendarPostEventMinutes < 0)
   {
      Print("Economic calendar filter minutes must be non-negative.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpCalendarCachePrefix == "" ||
      InpCalendarCacheMaxAgeSeconds < 1 ||
      InpCalendarCacheMaxEvents < 1)
   {
      Print("Invalid economic calendar cache settings.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   fast_ma_handle = iMA(_Symbol, InpSignalTimeframe, InpFastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   slow_ma_handle = iMA(_Symbol, InpSignalTimeframe, InpSlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(InpUseHigherTimeframeTrendFilter)
   {
      trend_slow_ma_handle = iMA(_Symbol, InpTrendFilterTimeframe, InpSlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      trend_baseline_ma_handle = iMA(_Symbol, InpTrendFilterTimeframe, InpTrendBaselineMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      trend_atr_handle = iATR(_Symbol, InpTrendFilterTimeframe, InpATRPeriod);
   }
   rsi_handle     = iRSI(_Symbol, InpSignalTimeframe, InpRSIPeriod, PRICE_CLOSE);
   atr_handle     = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);

   if(fast_ma_handle == INVALID_HANDLE || slow_ma_handle == INVALID_HANDLE ||
      (InpUseHigherTimeframeTrendFilter &&
       (trend_slow_ma_handle == INVALID_HANDLE || trend_baseline_ma_handle == INVALID_HANDLE || trend_atr_handle == INVALID_HANDLE)) ||
      rsi_handle == INVALID_HANDLE || atr_handle == INVALID_HANDLE)
   {
      Print("Failed to create indicator handles.");
      return(INIT_FAILED);
   }

   trade.SetExpertMagicNumber((long)InpMagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   FolderCreate(InpLogFolder);
   log_file_name = InpLogFolder + "\\CodexTrendPullbackEA-" + ConfiguredSymbol() + "-deals.tsv";
   signal_log_file_name = InpLogFolder + "\\CodexTrendPullbackEA-" + ConfiguredSymbol() + "-signals.tsv";

   RestoreStopLossCooldownState();

   LoadTelegramSettings();

   if(InpShowIndicators)
      Print("InpShowIndicators is deprecated. Use Scripts > CodexAutotrade > CodexShowIndicators for chart EMA/RSI/ATR.");

   if(InpUseHigherTimeframeTrendFilter)
      Print("CodexTrendPullbackEA initialized on ", _Symbol, " ", EnumToString(InpSignalTimeframe),
            " with trend filter ", EnumToString(InpTrendFilterTimeframe));
   else
      Print("CodexTrendPullbackEA initialized on ", _Symbol, " ", EnumToString(InpSignalTimeframe));

   Print("Startup config: target_symbol=",
         ConfiguredSymbol(),
         ", magic=",
         InpMagicNumber,
         ", max_spread_points=",
         InpMaxSpreadPoints,
         ", first_leg=",
         (InpEnableFirstLegEntry ? "ON" : "OFF"),
         ", pullback_confirm=",
         (InpRequireSecondPullbackConfirmation ? "2BAR" : "LEGACY"),
         ", htf_stop_atr_mult=",
         DoubleToString(InpTrendATRStopMultiplier, 2),
         ", continuation=REMOVED",
         ", add_on=",
         (InpAllowAddOnEntry ? "ON" : "OFF"),
         ", max_positions=",
         InpMaxPositionsPerDirection,
         ", add_on_profit_r=",
         DoubleToString(InpAddOnMinProfitR, 2),
         ", sl_cooldown_bars=",
         InpStopLossCooldownBars,
         ", trend_filter=",
         (InpUseHigherTimeframeTrendFilter ? "ON" : "OFF"),
         ", trend_tf=",
         EnumToString(InpTrendFilterTimeframe),
         ", min_trend_spread_atr=",
         DoubleToString(InpMinTrendSpreadATR, 2),
         ", min_slow_slope_atr=",
         DoubleToString(InpMinSlowMASlopeATR, 2),
         ", breakout_lookback=",
         InpFirstLegBreakoutLookback,
         ", tp_rr=",
         DoubleToString(InpTakeProfitRewardRisk, 2),
         ", lock_trigger_r=",
         DoubleToString(InpProfitLockTriggerR, 2),
         ", lock_amount_r=",
         DoubleToString(InpProfitLockAmountR, 2),
         ", max_spread_atr=",
         DoubleToString(InpMaxSpreadATR, 2),
         ", calendar_filter=",
         (InpUseEconomicCalendarFilter ? "ON" : "OFF"),
         ", calendar_currencies=",
         InpCalendarCurrencies,
         ", calendar_pre_min=",
         InpCalendarPreEventMinutes,
         ", calendar_post_min=",
         InpCalendarPostEventMinutes,
         ", calendar_refresh_sec=",
         InpCalendarRefreshSeconds,
         ", calendar_cache_prefix=",
         InpCalendarCachePrefix,
         ", calendar_cache_max_age_sec=",
         InpCalendarCacheMaxAgeSeconds,
         ", telegram=",
         (InpTelegramEnabled ? "ON" : "OFF"),
         ", telegram_config=",
         InpTelegramConfigFile,
         ", telegram_env=",
         (telegram_env == "" ? "-" : telegram_env),
         ", telegram_token=",
         (telegram_bot_token == "" ? "MISSING" : "SET"));

   LogTradingEnvironment("Startup trading environment");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ReleaseVisualIndicatorHandles();

   if(fast_ma_handle != INVALID_HANDLE)
      IndicatorRelease(fast_ma_handle);
   if(slow_ma_handle != INVALID_HANDLE)
      IndicatorRelease(slow_ma_handle);
   if(trend_slow_ma_handle != INVALID_HANDLE)
      IndicatorRelease(trend_slow_ma_handle);
   if(trend_baseline_ma_handle != INVALID_HANDLE)
      IndicatorRelease(trend_baseline_ma_handle);
   if(trend_atr_handle != INVALID_HANDLE)
      IndicatorRelease(trend_atr_handle);
   if(rsi_handle != INVALID_HANDLE)
      IndicatorRelease(rsi_handle);
   if(atr_handle != INVALID_HANDLE)
      IndicatorRelease(atr_handle);
}

void AttachVisualIndicators()
{
   ReleaseVisualIndicatorHandles();
}

bool AddChartIndicator(const long chart_id, const int subwindow, const int handle, string &indicator_name)
{
   ResetLastError();

   if(!ChartIndicatorAdd(chart_id, subwindow, handle))
      return(false);

   int after_total = ChartIndicatorsTotal(chart_id, subwindow);
   if(after_total > 0)
      indicator_name = ChartIndicatorName(chart_id, subwindow, after_total - 1);

   return(true);
}

void DetachVisualIndicators()
{
   long chart_id = ChartID();
   if(chart_id > 0)
   {
      DeleteChartIndicator(chart_id, visual_atr_window, visual_atr_name);
      DeleteChartIndicator(chart_id, visual_rsi_window, visual_rsi_name);
      DeleteChartIndicator(chart_id, 0, visual_baseline_ma_name);
      DeleteChartIndicator(chart_id, 0, visual_slow_ma_name);
      DeleteChartIndicator(chart_id, 0, visual_fast_ma_name);
   }

   ReleaseIndicatorHandle(visual_atr_handle);
   ReleaseIndicatorHandle(visual_rsi_handle);
   ReleaseIndicatorHandle(visual_baseline_ma_handle);
   ReleaseIndicatorHandle(visual_slow_ma_handle);
   ReleaseIndicatorHandle(visual_fast_ma_handle);
}

void ReleaseVisualIndicatorHandles()
{
   ReleaseIndicatorHandle(visual_atr_handle);
   ReleaseIndicatorHandle(visual_rsi_handle);
   ReleaseIndicatorHandle(visual_baseline_ma_handle);
   ReleaseIndicatorHandle(visual_slow_ma_handle);
   ReleaseIndicatorHandle(visual_fast_ma_handle);
}
void DeleteChartIndicator(const long chart_id, const int subwindow, const string indicator_name)
{
   if(subwindow < 0 || indicator_name == "")
      return;

   ResetLastError();
   if(!ChartIndicatorDelete(chart_id, subwindow, indicator_name))
      Print("ChartIndicatorDelete failed for ", indicator_name, ". Error=", GetLastError());
}

void ReleaseIndicatorHandle(int &handle)
{
   if(handle == INVALID_HANDLE)
      return;

   IndicatorRelease(handle);
   handle = INVALID_HANDLE;
}

void OnTick()
{
   ManageOpenPositions();

   if(!IsNewSignalBar())
      return;

   if(!IsTradingHour())
   {
      LogVerbose("Skipping entry: outside trading hours.");
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, last_signal_setup, "OUTSIDE_TRADING_HOURS", 0.0, 0.0, 0.0, 0);
      return;
   }

   if(!IsSpreadAcceptable())
   {
      LogVerbose("Skipping entry: spread too wide.");
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, last_signal_setup, "SPREAD_TOO_WIDE", 0.0, 0.0, 0.0, 0);
      return;
   }

   if(IsDailyLossLimitHit())
   {
      LogVerbose("Skipping entry: daily loss limit reached.");
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, last_signal_setup, "DAILY_LOSS_LIMIT", 0.0, 0.0, 0.0, 0);
      return;
   }

   if(IsSmallAccountGuardHit())
   {
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, last_signal_setup, "SMALL_ACCOUNT_GUARD", 0.0, 0.0, 0.0, 0);
      return;
   }

   double signal_atr_value = GetIndicatorValue(atr_handle, 1);
   if(signal_atr_value <= 0.0)
   {
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, last_signal_setup, "MISSING_SIGNAL_ATR", 0.0, 0.0, 0.0, 0);
      return;
   }

   double risk_atr_value = GetRiskReferenceATR(1);
   if(risk_atr_value <= 0.0)
   {
      AppendSignalSnapshot("SKIP", SIGNAL_NONE, last_signal_setup, "MISSING_RISK_ATR", 0.0, 0.0, 0.0, 0);
      return;
   }

   TradeSignal signal = SIGNAL_NONE;
   if(InpUseModelDirectTrading)
   {
      string model_direct_reason = "";
      if(!GetModelDirectSignal(signal, model_direct_reason))
      {
         LogVerbose("Skipping entry: model direct no signal. " + model_direct_reason);
         last_signal_setup = "MODEL_DIRECT";
         last_signal_skip_reason = "MODEL_DIRECT_NO_SIGNAL";
         AppendSignalSnapshot("SKIP", SIGNAL_NONE, last_signal_setup, "MODEL_DIRECT_NO_SIGNAL", 0.0, 0.0, 0.0, 0);
         return;
      }

      last_signal_is_first_leg = false;
      last_signal_setup = "MODEL_DIRECT";
      last_signal_skip_reason = model_direct_reason;
      LogVerbose("Model direct signal: " + model_direct_reason);
   }
   else
   {
      signal = DetectSignal();
      if(signal == SIGNAL_NONE)
      {
         AppendSignalSnapshot("SKIP", SIGNAL_NONE, last_signal_setup, last_signal_skip_reason, 0.0, 0.0, 0.0, 0);
         return;
      }
   }

   int cooldown_bars_remaining = 0;
   if(IsStopLossCooldownActive(signal, cooldown_bars_remaining))
   {
      LogVerbose("Skipping " + SignalToText(signal) +
                 ": stop-loss cooldown active (" +
                 IntegerToString(cooldown_bars_remaining) +
                 " bars remaining).");
      AppendSignalSnapshot("SKIP", signal, last_signal_setup, "STOP_LOSS_COOLDOWN", 0.0, 0.0, 0.0, 0);
      return;
   }

   if(!CanOpenForSignal(signal))
   {
      AppendSignalSnapshot("SKIP", signal, last_signal_setup, "POSITION_RULE_BLOCKED", 0.0, 0.0, 0.0, 0);
      return;
   }

   if(!InpUseModelDirectTrading)
   {
      string model_recommendation_reason = "";
      if(IsModelRecommendationBlocked(signal, model_recommendation_reason))
      {
         LogVerbose("Skipping " + SignalToText(signal) + ": model recommendation blocked. " + model_recommendation_reason);
         AppendSignalSnapshot("SKIP", signal, last_signal_setup, "MODEL_RECOMMENDATION_BLOCKED", 0.0, 0.0, 0.0, 0);
         return;
      }
   }

   PlaceOrder(signal, risk_atr_value);
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD || trans.deal == 0)
      return;

   if(!HistoryDealSelect(trans.deal))
      return;

   if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) != _Symbol)
      return;

   ulong deal_magic = (ulong)HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   if(deal_magic != InpMagicNumber)
      return;

   RegisterStopLossCooldown(trans.deal);
   AppendDealLog(trans.deal);
}

bool IsNewSignalBar()
{
   datetime current_bar_time = iTime(_Symbol, InpSignalTimeframe, 0);
   if(current_bar_time <= 0)
      return(false);

   if(last_bar_time == 0)
   {
      last_bar_time = current_bar_time;
      return(false);
   }

   if(current_bar_time != last_bar_time)
   {
      last_bar_time = current_bar_time;
      return(true);
   }

   return(false);
}

TradeSignal DetectSignal()
{
   last_signal_is_first_leg = false;
   last_signal_setup = "PULLBACK";
   last_signal_skip_reason = "NO_SIGNAL";

   int bars_to_copy = 4;
   if(InpEnableFirstLegEntry)
   {
      int first_leg_bars = InpFirstLegBreakoutLookback + 2;
      if(first_leg_bars > bars_to_copy)
         bars_to_copy = first_leg_bars;
   }

   MqlRates rates[];
   ArrayResize(rates, bars_to_copy);
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, InpSignalTimeframe, 0, bars_to_copy, rates) < bars_to_copy)
   {
      last_signal_skip_reason = "MISSING_RATES";
      return(SIGNAL_NONE);
   }

   double fast_ma[];
   double slow_ma[];
   double rsi_values[];
   ArrayResize(fast_ma, bars_to_copy);
   ArrayResize(slow_ma, bars_to_copy);
   ArrayResize(rsi_values, bars_to_copy);
   ArraySetAsSeries(fast_ma, true);
   ArraySetAsSeries(slow_ma, true);
   ArraySetAsSeries(rsi_values, true);

   if(CopyBuffer(fast_ma_handle, 0, 0, bars_to_copy, fast_ma) < bars_to_copy)
   {
      last_signal_skip_reason = "MISSING_FAST_MA";
      return(SIGNAL_NONE);
   }
   if(CopyBuffer(slow_ma_handle, 0, 0, bars_to_copy, slow_ma) < bars_to_copy)
   {
      last_signal_skip_reason = "MISSING_SLOW_MA";
      return(SIGNAL_NONE);
   }
   if(CopyBuffer(rsi_handle, 0, 0, bars_to_copy, rsi_values) < bars_to_copy)
   {
      last_signal_skip_reason = "MISSING_RSI";
      return(SIGNAL_NONE);
   }

   TradeSignal higher_timeframe_bias = GetHigherTimeframeTrendBias();

   bool bullish_trend = fast_ma[1] > slow_ma[1];
   bool bearish_trend = fast_ma[1] < slow_ma[1];

   double atr_value = GetIndicatorValue(atr_handle, 1);
   if(atr_value <= 0.0)
   {
      last_signal_skip_reason = "MISSING_SIGNAL_ATR";
      return(SIGNAL_NONE);
   }

   bool bullish_pullback = false;
   bool bearish_pullback = false;

   if(InpRequireSecondPullbackConfirmation)
   {
      bullish_pullback = rates[3].low <= fast_ma[3] &&
                         rates[2].close > fast_ma[2] &&
                         rates[2].close > rates[2].open &&
                         rates[1].close > fast_ma[1] &&
                         rates[1].close > slow_ma[1] &&
                         rates[1].close > rates[1].open &&
                         rates[1].high > rates[2].high &&
                         rsi_values[1] >= InpPullbackLongRSIMin &&
                         rsi_values[1] <= InpPullbackLongRSIMax;

      bearish_pullback = rates[3].high >= fast_ma[3] &&
                         rates[2].close < fast_ma[2] &&
                         rates[2].close < rates[2].open &&
                         rates[1].close < fast_ma[1] &&
                         rates[1].close < slow_ma[1] &&
                         rates[1].close < rates[1].open &&
                         rates[1].low < rates[2].low &&
                         rsi_values[1] >= InpPullbackShortRSIMin &&
                         rsi_values[1] <= InpPullbackShortRSIMax;
   }
   else
   {
      bullish_pullback = rates[2].low <= fast_ma[2] &&
                         rates[1].close > fast_ma[1] &&
                         rates[1].close > rates[1].open &&
                         rsi_values[1] >= InpPullbackLongRSIMin &&
                         rsi_values[1] <= InpPullbackLongRSIMax;

      bearish_pullback = rates[2].high >= fast_ma[2] &&
                         rates[1].close < fast_ma[1] &&
                         rates[1].close < rates[1].open &&
                         rsi_values[1] >= InpPullbackShortRSIMin &&
                         rsi_values[1] <= InpPullbackShortRSIMax;
   }

   if(InpAllowLong && bullish_trend && bullish_pullback)
   {
      if(InpUseHigherTimeframeTrendFilter && higher_timeframe_bias != SIGNAL_BUY)
      {
         LogVerbose("Skipping BUY: higher timeframe bias is " + SignalToText(higher_timeframe_bias) + ".");
         last_signal_skip_reason = "HTF_BIAS_NOT_BUY";
         return(SIGNAL_NONE);
      }
      return(SIGNAL_BUY);
   }

   if(InpAllowShort && bearish_trend && bearish_pullback)
   {
      if(InpUseHigherTimeframeTrendFilter && higher_timeframe_bias != SIGNAL_SELL)
      {
         LogVerbose("Skipping SELL: higher timeframe bias is " + SignalToText(higher_timeframe_bias) + ".");
         last_signal_skip_reason = "HTF_BIAS_NOT_SELL";
         return(SIGNAL_NONE);
      }
      return(SIGNAL_SELL);
   }

   TradeSignal first_leg_signal = DetectFirstLegSignal(rates, fast_ma, slow_ma, rsi_values, higher_timeframe_bias);
   if(first_leg_signal != SIGNAL_NONE)
   {
      last_signal_is_first_leg = true;
      last_signal_setup = "FIRST_LEG";
      return(first_leg_signal);
   }

   return(SIGNAL_NONE);
}

double GetRiskReferenceATR(const int shift)
{
   double signal_atr_value = GetIndicatorValue(atr_handle, shift);
   if(signal_atr_value <= 0.0)
      return(0.0);

   double reference_atr = signal_atr_value;
   if(InpUseHigherTimeframeTrendFilter && trend_atr_handle != INVALID_HANDLE)
   {
      int trend_shift = (shift > 0 ? 1 : 0);
      double trend_atr_value = GetIndicatorValue(trend_atr_handle, trend_shift);
      if(trend_atr_value > 0.0)
         reference_atr = MathMax(reference_atr, trend_atr_value * InpTrendATRStopMultiplier);
   }

   return(reference_atr);
}

TradeSignal GetHigherTimeframeTrendBias()
{
   if(!InpUseHigherTimeframeTrendFilter)
      return(SIGNAL_NONE);

   if(trend_slow_ma_handle == INVALID_HANDLE)
      return(SIGNAL_NONE);
   if(trend_baseline_ma_handle == INVALID_HANDLE)
      return(SIGNAL_NONE);

   int bars_to_copy = InpTrendConfirmBars + 1;
   double trend_slow_ma[];
   double trend_baseline_ma[];
   ArrayResize(trend_slow_ma, bars_to_copy);
   ArrayResize(trend_baseline_ma, bars_to_copy);
   ArraySetAsSeries(trend_slow_ma, true);
   ArraySetAsSeries(trend_baseline_ma, true);
   if(CopyBuffer(trend_slow_ma_handle, 0, 0, bars_to_copy, trend_slow_ma) < bars_to_copy)
      return(SIGNAL_NONE);
   if(CopyBuffer(trend_baseline_ma_handle, 0, 0, bars_to_copy, trend_baseline_ma) < bars_to_copy)
      return(SIGNAL_NONE);

   MqlRates trend_rates[];
   ArrayResize(trend_rates, 2);
   ArraySetAsSeries(trend_rates, true);
   if(CopyRates(_Symbol, InpTrendFilterTimeframe, 0, 2, trend_rates) < 2)
      return(SIGNAL_NONE);

   bool structure_bullish = trend_slow_ma[1] > trend_baseline_ma[1];
   bool structure_bearish = trend_slow_ma[1] < trend_baseline_ma[1];
   bool close_above_trend_ma = trend_rates[1].close > trend_slow_ma[1] && trend_rates[1].close > trend_baseline_ma[1];
   bool close_below_trend_ma = trend_rates[1].close < trend_slow_ma[1] && trend_rates[1].close < trend_baseline_ma[1];

   if(structure_bullish && close_above_trend_ma)
      return(SIGNAL_BUY);

   if(structure_bearish && close_below_trend_ma)
      return(SIGNAL_SELL);

   return(SIGNAL_NONE);
}

TradeSignal DetectFirstLegSignal(const MqlRates &rates[],
                                 const double &fast_ma[],
                                 const double &slow_ma[],
                                 const double &rsi_values[],
                                 const TradeSignal higher_timeframe_bias)
{
   if(!InpEnableFirstLegEntry)
      return(SIGNAL_NONE);

   int lookback = InpFirstLegBreakoutLookback;
   if(lookback < 2)
      lookback = 2;

   if(ArraySize(rates) < lookback + 2 ||
      ArraySize(fast_ma) < lookback + 2 ||
      ArraySize(slow_ma) < lookback + 2 ||
      ArraySize(rsi_values) < lookback + 2)
      return(SIGNAL_NONE);

   double prior_high = rates[2].high;
   double prior_low = rates[2].low;
   bool touched_bullish_zone = false;
   bool touched_bearish_zone = false;

   for(int i = 2; i <= lookback + 1; ++i)
   {
      prior_high = MathMax(prior_high, rates[i].high);
      prior_low = MathMin(prior_low, rates[i].low);

      if(rates[i].low <= fast_ma[i] || rates[i].low <= slow_ma[i])
         touched_bullish_zone = true;

      if(rates[i].high >= fast_ma[i] || rates[i].high >= slow_ma[i])
         touched_bearish_zone = true;
   }

   bool bullish_breakout = rates[1].close > prior_high &&
                           rates[1].close > fast_ma[1] &&
                           rates[1].close > slow_ma[1] &&
                           rates[1].close > rates[1].open &&
                           rsi_values[1] >= InpFirstLegLongRSIMin &&
                           rsi_values[1] <= InpFirstLegLongRSIMax;

   bool bearish_breakout = rates[1].close < prior_low &&
                           rates[1].close < fast_ma[1] &&
                           rates[1].close < slow_ma[1] &&
                           rates[1].close < rates[1].open &&
                           rsi_values[1] >= InpFirstLegShortRSIMin &&
                           rsi_values[1] <= InpFirstLegShortRSIMax;

   bool bullish_structure = fast_ma[1] >= slow_ma[1] || fast_ma[1] > fast_ma[2];
   bool bearish_structure = fast_ma[1] <= slow_ma[1] || fast_ma[1] < fast_ma[2];
   bool long_bias_ok = !InpUseHigherTimeframeTrendFilter || higher_timeframe_bias == SIGNAL_BUY;
   bool short_bias_ok = !InpUseHigherTimeframeTrendFilter || higher_timeframe_bias == SIGNAL_SELL;

   if(InpAllowLong && long_bias_ok && touched_bullish_zone && bullish_structure && bullish_breakout)
      return(SIGNAL_BUY);

   if(InpAllowShort && short_bias_ok && touched_bearish_zone && bearish_structure && bearish_breakout)
      return(SIGNAL_SELL);

   return(SIGNAL_NONE);
}

void PlaceOrder(const TradeSignal signal, const double risk_atr_value)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   double order_risk_percent = InpRiskPerTradePercent;
   double model_stop_atr = InpStopLossATR;
   double model_target_atr = InpStopLossATR * InpTakeProfitRewardRisk;
   int model_max_positions = InpMaxPositionsPerDirection;
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
         LogVerbose("Skipping entry: missing model execution plan. " + model_execution_reason);
         AppendSignalSnapshot("SKIP", signal, last_signal_setup, "MODEL_EXECUTION_PLAN_MISSING", 0.0, 0.0, 0.0, 0);
         return;
      }
   }

   if(InpUseModelDirectTrading && InpUseModelExecutionPlan &&
      model_max_positions > 0 &&
      CountModelStrategyPositions(signal) >= model_max_positions)
   {
      LogVerbose("Skipping " + SignalToText(signal) +
                 ": model execution max same-direction positions reached. max=" +
                 IntegerToString(model_max_positions));
      AppendSignalSnapshot("SKIP", signal, last_signal_setup, "MODEL_EXECUTION_POSITION_LIMIT", 0.0, 0.0, 0.0, 0);
      return;
   }

   if(IsCoexistencePositionGuardHit(signal))
   {
      AppendSignalSnapshot("SKIP", signal, last_signal_setup, "WINDOWS_BTC_COEXISTENCE_LIMIT", 0.0, 0.0, 0.0, 0);
      return;
   }

   double stop_distance = risk_atr_value * model_stop_atr;
   if(stop_distance <= 0.0)
      return;

   bool used_min_volume_fallback = false;
   double effective_risk_percent = 0.0;
   double volume = CalculatePositionSizeForRisk(stop_distance,
                                                order_risk_percent,
                                                used_min_volume_fallback,
                                                effective_risk_percent);
   if(volume <= 0.0)
   {
      LogVerbose("Skipping entry: calculated volume is below minimum or fallback risk cap.");
      AppendSignalSnapshot("SKIP", signal, last_signal_setup, "VOLUME_BELOW_MIN_OR_FALLBACK_CAP", volume, 0.0, 0.0, 0);
      LogPositionSizeDiagnostic(risk_atr_value, stop_distance, effective_risk_percent);
      return;
   }

   if(InpMaxVolumePerTrade > 0.0 && volume > InpMaxVolumePerTrade)
   {
      double capped_volume = NormalizeVolume(InpMaxVolumePerTrade);
      if(capped_volume <= 0.0)
      {
         LogVerbose("Skipping entry: max volume cap is below symbol minimum. cap=" +
                    DoubleToString(InpMaxVolumePerTrade, 2));
         AppendSignalSnapshot("SKIP", signal, last_signal_setup, "MAX_VOLUME_CAP_BELOW_MIN", volume, 0.0, 0.0, 0);
         return;
      }

      LogVerbose("Capping volume for Windows BTC small account: original=" +
                 DoubleToString(volume, 2) +
                 ", capped=" +
                 DoubleToString(capped_volume, 2));
      volume = capped_volume;
   }

   if(used_min_volume_fallback)
   {
      LogVerbose("Using minimum volume fallback: volume=" +
                 DoubleToString(volume, 2) +
                 " effective_risk=" +
                 DoubleToString(effective_risk_percent, 2) +
                 "%");
   }

   double min_stop_distance = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(stop_distance < min_stop_distance)
      stop_distance = min_stop_distance;
   double take_distance = risk_atr_value * model_target_atr;
   if(take_distance < min_stop_distance)
      take_distance = min_stop_distance;

   double sl = 0.0;
   double tp = 0.0;
   bool placed = false;
   string comment = "CodexTP-" + ConfiguredSymbol();
   if(last_signal_setup == "FIRST_LEG")
      comment += "-FL";

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
         comment += "-H" + IntegerToString(comment_hold_bars);
      }
   }

   trade.SetTypeFillingBySymbol(_Symbol);

   if(signal == SIGNAL_BUY)
   {
      sl = NormalizePrice(tick.bid - stop_distance);
      tp = NormalizePrice(tick.ask + take_distance);
      placed = trade.Buy(volume, _Symbol, 0.0, sl, tp, comment);
   }
   else if(signal == SIGNAL_SELL)
   {
      sl = NormalizePrice(tick.ask + stop_distance);
      tp = NormalizePrice(tick.bid - take_distance);
      placed = trade.Sell(volume, _Symbol, 0.0, sl, tp, comment);
   }

   if(!placed)
   {
      LogOrderFailure("Order failed", sl, tp, stop_distance);
      AppendSignalSnapshot("ERROR", signal, last_signal_setup, "ORDER_FAILED", volume, sl, tp, 0);
      return;
   }

   Print("Order placed: ", EnumToString((ENUM_ORDER_TYPE)trade.RequestType()),
         " volume=", DoubleToString(volume, 2),
         " sl=", DoubleToString(sl, _Digits),
         " tp=", DoubleToString(tp, _Digits),
         " setup=", last_signal_setup,
         " risk_distance=", DoubleToString(stop_distance, _Digits),
         " model_execution=", model_execution_reason);

   MarkModelRecommendationEntry(signal);

   AppendSignalSnapshot("ORDER", signal, last_signal_setup, "PLACED", volume, sl, tp, trade.ResultOrder());

   SendTelegramOrderNotification(signal, volume, trade.ResultPrice(), sl, tp, stop_distance);
}

string PriceToText(const double price)
{
   if(price <= 0.0)
      return("-");

   return(DoubleToString(price, _Digits));
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

   return(encoded);
}

bool ParseTelegramConfigLine(string line, string &key, string &value)
{
   StringTrimLeft(line);
   StringTrimRight(line);
   if(line == "")
      return(false);

   ushort first_char = StringGetCharacter(line, 0);
   if(first_char == '#' || first_char == ';')
      return(false);

   int separator = StringFind(line, ":");
   int equals_separator = StringFind(line, "=");
   if(separator < 0 || (equals_separator >= 0 && equals_separator < separator))
      separator = equals_separator;
   if(separator <= 0)
      return(false);

   key = StringSubstr(line, 0, separator);
   value = StringSubstr(line, separator + 1);
   StringTrimLeft(key);
   StringTrimRight(key);
   StringTrimLeft(value);
   StringTrimRight(value);
   StringToLower(key);

   return(key != "" && value != "");
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

   return(base_url);
}

string BuildTelegramOrderMessage(const TradeSignal signal,
                                 const double volume,
                                 const double result_price,
                                 const double sl,
                                 const double tp,
                                 const double risk_distance)
{
   string direction = SignalToText(signal);
   string env = telegram_env;
   if(env == "")
      env = "-";
   string price = PriceToText(result_price);
   if(price == "-")
   {
      if(signal == SIGNAL_BUY)
         price = PriceToText(trade.RequestPrice());
      else if(signal == SIGNAL_SELL)
         price = PriceToText(trade.RequestPrice());
   }

   return("[" + ConfiguredSymbol() + "] " + direction + " opened\n" +
          "env: " + env + "\n" +
          "symbol: " + _Symbol + "\n" +
          "volume: " + DoubleToString(volume, 2) + "\n" +
          "price: " + price + "\n" +
          "sl: " + PriceToText(sl) + "\n" +
          "tp: " + PriceToText(tp) + "\n" +
          "setup: " + last_signal_setup + "\n" +
          "risk_distance: " + DoubleToString(risk_distance, _Digits) + "\n" +
          "order: " + IntegerToString((long)trade.ResultOrder()) + "\n" +
          "deal: " + IntegerToString((long)trade.ResultDeal()) + "\n" +
          "account: " + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) + "\n" +
          "server: " + AccountInfoString(ACCOUNT_SERVER) + "\n" +
          "time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
}

void SendTelegramOrderNotification(const TradeSignal signal,
                                   const double volume,
                                   const double result_price,
                                   const double sl,
                                   const double tp,
                                   const double risk_distance)
{
   if(!InpTelegramEnabled)
      return;

   if(telegram_bot_token == "" || telegram_chat_id == "")
   {
      LogVerbose("Telegram notification skipped: missing bot token or chat id.");
      return;
   }

   string url = TelegramBaseURL() + "/bot" + telegram_bot_token + "/sendMessage";
   string body = "chat_id=" + UrlEncode(telegram_chat_id) +
                 "&text=" + UrlEncode(BuildTelegramOrderMessage(signal, volume, result_price, sl, tp, risk_distance)) +
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
      return;
   }

   if(status < 200 || status >= 300)
   {
      Print("Telegram notification failed: HTTP status=", status,
            ". Trading is unaffected. Response=",
            CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8));
      return;
   }

   LogVerbose("Telegram notification sent.");
}

bool IsPositionProtectedByStop(const long position_type, const double open_price, const double current_sl)
{
   if(current_sl <= 0.0)
      return(false);

   if(position_type == POSITION_TYPE_BUY)
      return(current_sl > open_price);

   if(position_type == POSITION_TYPE_SELL)
      return(current_sl < open_price);

   return(false);
}

int ExtractModelHoldBarsFromComment(const string comment)
{
   const int marker = StringFind(comment, "-H");
   if(marker < 0)
      return(0);

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
      return(0);

   return((int)StringToInteger(digits));
}

bool IsModelHoldTimedOut(const datetime open_time, const int hold_bars, int &elapsed_seconds, int &timeout_seconds)
{
   elapsed_seconds = 0;
   timeout_seconds = 0;

   if(!InpModelTimeExitEnabled || hold_bars <= 0 || open_time <= 0)
      return(false);

   double effective_minutes = (double)hold_bars * MathMax(0.10, InpModelTimeExitGraceMultiplier);
   if(effective_minutes < (double)InpModelTimeExitMinMinutes)
      effective_minutes = (double)InpModelTimeExitMinMinutes;

   timeout_seconds = (int)MathRound(effective_minutes * 60.0);
   if(timeout_seconds <= 0)
      return(false);

   elapsed_seconds = (int)(TimeCurrent() - open_time);
   return(elapsed_seconds >= timeout_seconds);
}

void ManageOpenPositions()
{
   if(CountStrategyPositions() == 0)
      return;

   double atr_value = GetRiskReferenceATR(0);
   if(atr_value <= 0.0)
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(magic != InpMagicNumber)
         continue;

      long position_type = PositionGetInteger(POSITION_TYPE);
      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double current_sl = PositionGetDouble(POSITION_SL);
      double current_tp = PositionGetDouble(POSITION_TP);
      double new_sl = current_sl;
      double new_tp = current_tp;
      bool should_modify = false;
      TradeSignal position_signal = (position_type == POSITION_TYPE_BUY ? SIGNAL_BUY : SIGNAL_SELL);
      double model_trail_start_atr = 0.0;
      double model_trail_distance_atr = 0.0;
      int model_hold_bars = 0;
      string model_management_reason = "";
      bool has_model_management_plan = InpUseModelDirectTrading &&
                                       InpUseModelExecutionPlan &&
                                       GetModelPositionManagementPlan(position_signal,
                                                                      model_trail_start_atr,
                                                                      model_trail_distance_atr,
                                                                      model_hold_bars,
                                                                      model_management_reason);
      const int comment_hold_bars = ExtractModelHoldBarsFromComment(PositionGetString(POSITION_COMMENT));
      if(comment_hold_bars > 0)
         model_hold_bars = comment_hold_bars;

      bool use_model_trailing = has_model_management_plan && InpModelExecutionUseTrailing;
      bool use_model_time_exit = InpUseModelDirectTrading &&
                                 InpUseModelExecutionPlan &&
                                 InpModelTimeExitEnabled &&
                                 model_hold_bars > 0;

      if(position_type == POSITION_TYPE_BUY)
      {
         double profit_distance = tick.bid - open_price;
         double risk_distance = GetPositionReferenceRiskDistance(position_type, open_price, current_sl, current_tp, atr_value);
         if(risk_distance <= 0.0)
            continue;

         double profit_r = profit_distance / risk_distance;
         int elapsed_seconds = 0;
         int timeout_seconds = 0;
         bool protected_by_stop = IsPositionProtectedByStop(position_type, open_price, current_sl) ||
                                  IsPositionProtectedByStop(position_type, open_price, new_sl);
         if(use_model_time_exit &&
            !protected_by_stop &&
            (InpProfitLockTriggerR <= 0.0 || profit_r < InpProfitLockTriggerR) &&
            IsModelHoldTimedOut(open_time, model_hold_bars, elapsed_seconds, timeout_seconds))
         {
            Print("Closing ",
                  (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                  ": model hold timeout before profit lock. hold_bars=",
                  model_hold_bars,
                  ", elapsed_sec=",
                  elapsed_seconds,
                  ", timeout_sec=",
                  timeout_seconds,
                  ", profit_r=",
                  DoubleToString(profit_r, 3));
            if(trade.PositionClose(ticket))
            {
               if(position_type == POSITION_TYPE_BUY)
                  last_long_stop_loss_time = TimeCurrent();
               else if(position_type == POSITION_TYPE_SELL)
                  last_short_stop_loss_time = TimeCurrent();
            }
            else
            {
               Print("Model hold timeout close failed: ", trade.ResultRetcodeDescription());
            }
            continue;
         }

         if(InpProfitLockTriggerR > 0.0 &&
            InpProfitLockAmountR > 0.0 &&
            profit_r >= InpProfitLockTriggerR)
         {
            double profit_lock_sl = GetProfitLockStopPrice(POSITION_TYPE_BUY, open_price, risk_distance, InpProfitLockAmountR);
            if(profit_lock_sl > 0.0 && (current_sl == 0.0 || profit_lock_sl > current_sl) &&
               (new_sl == 0.0 || profit_lock_sl > new_sl))
            {
               new_sl = profit_lock_sl;
               should_modify = true;
            }
         }

         if(InpRemoveTakeProfitOnLock &&
            InpRemoveTakeProfitTriggerR > 0.0 &&
            profit_r >= InpRemoveTakeProfitTriggerR &&
            current_tp > 0.0)
         {
            new_tp = 0.0;
            should_modify = true;
         }

         if(profit_r >= InpBreakEvenTriggerR)
         {
            double breakeven_sl = NormalizePrice(open_price + (2.0 * _Point));
            if(new_sl == 0.0 || breakeven_sl > new_sl)
            {
               new_sl = breakeven_sl;
               should_modify = true;
            }
         }

         double trail_start_distance = use_model_trailing ? atr_value * model_trail_start_atr : risk_distance * InpTrailStartR;
         double trail_distance = use_model_trailing ? atr_value * model_trail_distance_atr : risk_distance * InpTrailDistanceR;
         if(profit_distance >= trail_start_distance && trail_distance > 0.0)
         {
            if(use_model_trailing && current_tp > 0.0)
            {
               new_tp = 0.0;
               should_modify = true;
            }

            double trail_sl = NormalizePrice(tick.bid - trail_distance);
            if(new_sl == 0.0 || trail_sl > new_sl)
            {
               new_sl = trail_sl;
               should_modify = true;
            }
         }

         double max_allowed_sl = NormalizePrice(tick.bid - ((double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point));
         if(new_sl > max_allowed_sl)
            new_sl = max_allowed_sl;
      }
      else if(position_type == POSITION_TYPE_SELL)
      {
         double profit_distance = open_price - tick.ask;
         double risk_distance = GetPositionReferenceRiskDistance(position_type, open_price, current_sl, current_tp, atr_value);
         if(risk_distance <= 0.0)
            continue;

         double profit_r = profit_distance / risk_distance;
         int elapsed_seconds = 0;
         int timeout_seconds = 0;
         bool protected_by_stop = IsPositionProtectedByStop(position_type, open_price, current_sl) ||
                                  IsPositionProtectedByStop(position_type, open_price, new_sl);
         if(use_model_time_exit &&
            !protected_by_stop &&
            (InpProfitLockTriggerR <= 0.0 || profit_r < InpProfitLockTriggerR) &&
            IsModelHoldTimedOut(open_time, model_hold_bars, elapsed_seconds, timeout_seconds))
         {
            Print("Closing SELL: model hold timeout before profit lock. hold_bars=",
                  model_hold_bars,
                  ", elapsed_sec=",
                  elapsed_seconds,
                  ", timeout_sec=",
                  timeout_seconds,
                  ", profit_r=",
                  DoubleToString(profit_r, 3));
            if(trade.PositionClose(ticket))
               last_short_stop_loss_time = TimeCurrent();
            else
               Print("Model hold timeout close failed: ", trade.ResultRetcodeDescription());
            continue;
         }

         if(InpProfitLockTriggerR > 0.0 &&
            InpProfitLockAmountR > 0.0 &&
            profit_r >= InpProfitLockTriggerR)
         {
            double profit_lock_sl = GetProfitLockStopPrice(POSITION_TYPE_SELL, open_price, risk_distance, InpProfitLockAmountR);
            if(profit_lock_sl > 0.0 && (current_sl == 0.0 || profit_lock_sl < current_sl) &&
               (new_sl == 0.0 || profit_lock_sl < new_sl))
            {
               new_sl = profit_lock_sl;
               should_modify = true;
            }
         }

         if(InpRemoveTakeProfitOnLock &&
            InpRemoveTakeProfitTriggerR > 0.0 &&
            profit_r >= InpRemoveTakeProfitTriggerR &&
            current_tp > 0.0)
         {
            new_tp = 0.0;
            should_modify = true;
         }

         if(profit_r >= InpBreakEvenTriggerR)
         {
            double breakeven_sl = NormalizePrice(open_price - (2.0 * _Point));
            if(new_sl == 0.0 || breakeven_sl < new_sl)
            {
               new_sl = breakeven_sl;
               should_modify = true;
            }
         }

         double trail_start_distance = use_model_trailing ? atr_value * model_trail_start_atr : risk_distance * InpTrailStartR;
         double trail_distance = use_model_trailing ? atr_value * model_trail_distance_atr : risk_distance * InpTrailDistanceR;
         if(profit_distance >= trail_start_distance && trail_distance > 0.0)
         {
            if(use_model_trailing && current_tp > 0.0)
            {
               new_tp = 0.0;
               should_modify = true;
            }

            double trail_sl = NormalizePrice(tick.ask + trail_distance);
            if(new_sl == 0.0 || trail_sl < new_sl)
            {
               new_sl = trail_sl;
               should_modify = true;
            }
         }

         double min_allowed_sl = NormalizePrice(tick.ask + ((double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point));
         if(new_sl < min_allowed_sl)
            new_sl = min_allowed_sl;
      }

      if(!should_modify)
         continue;

      if(new_sl == current_sl && new_tp == current_tp)
         continue;

      if(!trade.PositionModify(ticket, new_sl, new_tp))
         Print("Position modify failed: ", trade.ResultRetcodeDescription());
   }
}

bool IsTradingHour()
{
   if(!InpUseTradingHours)
      return(true);

   int start_hour = InpTradeStartHour;
   int end_hour   = InpTradeEndHour;
   if(start_hour == end_hour)
      return(true);

   MqlDateTime server_time;
   TimeToStruct(TimeCurrent(), server_time);

   if(start_hour < end_hour)
      return(server_time.hour >= start_hour && server_time.hour < end_hour);

   return(server_time.hour >= start_hour || server_time.hour < end_hour);
}

bool IsSpreadAcceptable()
{
   long spread_points = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread_points < 0)
      return(false);

   if(InpMaxSpreadPoints > 0 && spread_points > InpMaxSpreadPoints)
      return(false);

   if(InpMaxSpreadATR > 0.0)
   {
      double atr_value = GetIndicatorValue(atr_handle, 1);
      if(atr_value <= 0.0)
         return(false);

      double spread_price = (double)spread_points * _Point;
      if(spread_price > atr_value * InpMaxSpreadATR)
         return(false);
   }

   return(true);
}

bool IsDailyLossLimitHit()
{
   if(InpMaxDailyLossPercent <= 0.0 && InpMaxDailyLossMoney <= 0.0)
      return(false);

   double today_closed_pnl = GetTodayClosedPnL();
   double loss_limit = 0.0;
   if(InpMaxDailyLossMoney > 0.0)
      loss_limit = InpMaxDailyLossMoney;

   if(InpMaxDailyLossPercent > 0.0)
   {
      double percent_limit = AccountInfoDouble(ACCOUNT_BALANCE) * (InpMaxDailyLossPercent / 100.0);
      if(loss_limit <= 0.0 || percent_limit < loss_limit)
         loss_limit = percent_limit;
   }

   if(loss_limit <= 0.0)
      return(false);

   if(today_closed_pnl <= (-1.0 * loss_limit))
   {
      LogVerbose("Small-account daily loss guard active: today_pnl=" +
                 DoubleToString(today_closed_pnl, 2) +
                 ", limit=" +
                 DoubleToString(loss_limit, 2));
      return(true);
   }

   return(false);
}

bool IsWindowsCoexistenceMagic(const ulong magic)
{
   if(magic == InpMagicNumber)
      return(true);
   return(InpWindowsCoexistenceMode &&
          InpPeerPendingModelMagicNumber > 0 &&
          magic == InpPeerPendingModelMagicNumber);
}

int CountCoexistencePositions(const TradeSignal signal_filter = SIGNAL_NONE)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!IsWindowsCoexistenceMagic(magic))
         continue;

      if(signal_filter != SIGNAL_NONE)
      {
         const long position_type = PositionGetInteger(POSITION_TYPE);
         const TradeSignal position_signal = position_type == POSITION_TYPE_BUY ? SIGNAL_BUY : SIGNAL_SELL;
         if(position_signal != signal_filter)
            continue;
      }

      count++;
   }
   return(count);
}

double SumCoexistenceVolume()
{
   double volume = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!IsWindowsCoexistenceMagic(magic))
         continue;

      volume += PositionGetDouble(POSITION_VOLUME);
   }
   return(volume);
}

bool IsCoexistencePositionGuardHit(const TradeSignal signal)
{
   if(!InpWindowsCoexistenceMode)
      return(false);

   if(InpBlockOppositeCoexistencePositions && signal != SIGNAL_NONE)
   {
      const TradeSignal opposite_signal = signal == SIGNAL_BUY ? SIGNAL_SELL : SIGNAL_BUY;
      if(CountCoexistencePositions(opposite_signal) > 0)
      {
         LogVerbose("Skipping " + SignalToText(signal) +
                    ": opposite Windows BTC EA position already exists.");
         return(true);
      }
   }

   if(InpMaxCombinedBTCPositions > 0 &&
      CountCoexistencePositions() >= InpMaxCombinedBTCPositions)
   {
      LogVerbose("Skipping " + SignalToText(signal) +
                 ": Windows BTC combined position limit reached. max=" +
                 IntegerToString(InpMaxCombinedBTCPositions));
      return(true);
   }

   if(InpMaxCombinedBTCVolume > 0.0 &&
      SumCoexistenceVolume() >= InpMaxCombinedBTCVolume - 0.0000001)
   {
      LogVerbose("Skipping " + SignalToText(signal) +
                 ": Windows BTC combined volume limit reached. max_volume=" +
                 DoubleToString(InpMaxCombinedBTCVolume,
                                VolumeDigits(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP))));
      return(true);
   }

   return(false);
}

bool IsSmallAccountGuardHit()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(InpMinEquityToTrade > 0.0 && equity < InpMinEquityToTrade)
   {
      LogVerbose("Small-account equity guard active: equity=" +
                 DoubleToString(equity, 2) +
                 ", min_equity=" +
                 DoubleToString(InpMinEquityToTrade, 2));
      return(true);
   }

   if(InpMaxConsecutiveLosses > 0)
   {
      int losses = CountConsecutiveClosedLosses();
      if(losses >= InpMaxConsecutiveLosses)
      {
         LogVerbose("Small-account consecutive-loss guard active: losses=" +
                    IntegerToString(losses) +
                    ", max=" +
                    IntegerToString(InpMaxConsecutiveLosses));
         return(true);
      }
   }

   return(false);
}

int CountConsecutiveClosedLosses()
{
   if(!HistorySelect(0, TimeCurrent()))
      return(0);

   int losses = 0;
   int total_deals = HistoryDealsTotal();
   for(int i = total_deals - 1; i >= 0; --i)
   {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket == 0)
         continue;

      if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != _Symbol)
         continue;

      ulong magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      if(!IsWindowsCoexistenceMagic(magic))
         continue;

      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      double pnl = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT) +
                   HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION) +
                   HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
      if(pnl < 0.0)
      {
         losses++;
         continue;
      }

      break;
   }

   return(losses);
}

bool IsEconomicCalendarRiskActive()
{
   if(!InpUseEconomicCalendarFilter)
      return(false);

   datetime now_time = TimeCurrent();

   double service_running = 0.0;
   if(!ReadCalendarCacheValue("service_running", service_running) || service_running < 0.5)
   {
      Print("Economic calendar cache service is not running or not initialized.");
      return(InpBlockOnCalendarError);
   }

   double updating = 0.0;
   if(ReadCalendarCacheValue("updating", updating) && updating > 0.5)
      return(InpBlockOnCalendarError);

   double cache_error = 0.0;
   if(ReadCalendarCacheValue("error", cache_error) && cache_error > 0.5)
   {
      Print("Economic calendar cache service reported an error.");
      return(InpBlockOnCalendarError);
   }

   double updated_at_value = 0.0;
   if(!ReadCalendarCacheValue("updated_at", updated_at_value))
      return(InpBlockOnCalendarError);

   datetime updated_at = (datetime)updated_at_value;
   if(updated_at <= 0 || now_time - updated_at > InpCalendarCacheMaxAgeSeconds)
   {
      Print("Economic calendar cache is stale. updated_at=",
            TimeToString(updated_at, TIME_DATE | TIME_SECONDS));
      return(InpBlockOnCalendarError);
   }

   double count_value = 0.0;
   if(!ReadCalendarCacheValue("count", count_value))
      return(InpBlockOnCalendarError);

   int event_count = (int)count_value;
   if(event_count > InpCalendarCacheMaxEvents)
      event_count = InpCalendarCacheMaxEvents;

   for(int i = 0; i < event_count; ++i)
   {
      double event_time_value = 0.0;
      if(!ReadCalendarCacheEventTime(i, event_time_value))
         continue;

      datetime event_time = (datetime)event_time_value;
      datetime risk_start_time = event_time - (datetime)(InpCalendarPreEventMinutes * 60);
      datetime risk_end_time = event_time + (datetime)(InpCalendarPostEventMinutes * 60);
      if(now_time < risk_start_time || now_time > risk_end_time)
         continue;

      LogVerbose("Economic calendar risk: " +
                 InpCalendarCachePrefix +
                 " event at " +
                 TimeToString(event_time, TIME_DATE | TIME_MINUTES));
      return(true);
   }

   return(false);
}

bool ReadCalendarCacheValue(const string field, double &value)
{
   string key = CalendarCacheKey(field);
   if(!GlobalVariableCheck(key))
      return(false);

   value = GlobalVariableGet(key);
   return(true);
}

bool ReadCalendarCacheEventTime(const int index, double &value)
{
   string key = InpCalendarCachePrefix + ".event." + IntegerToString(index) + ".time";
   if(!GlobalVariableCheck(key))
      return(false);

   value = GlobalVariableGet(key);
   return(true);
}

string CalendarCacheKey(const string field)
{
   return(InpCalendarCachePrefix + "." + field);
}

double GetTodayClosedPnL()
{
   MqlDateTime now_struct;
   TimeToStruct(TimeCurrent(), now_struct);
   now_struct.hour = 0;
   now_struct.min = 0;
   now_struct.sec = 0;

   datetime day_start = StructToTime(now_struct);
   datetime now_time = TimeCurrent();

   if(!HistorySelect(day_start, now_time))
      return(0.0);

   double pnl = 0.0;
   int total_deals = HistoryDealsTotal();
   for(int i = 0; i < total_deals; ++i)
   {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket == 0)
         continue;

      if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != _Symbol)
         continue;

      ulong magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      if(!IsWindowsCoexistenceMagic(magic))
         continue;

      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      pnl += HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
      pnl += HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
      pnl += HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
   }

   return(pnl);
}

int CountStrategyPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(magic != InpMagicNumber)
         continue;

      count++;
   }

   return(count);
}

bool IsPositionSecured(const long position_type, const double open_price, const double current_sl)
{
   if(current_sl <= 0.0)
      return(false);

   if(position_type == POSITION_TYPE_BUY)
      return(current_sl >= open_price);

   if(position_type == POSITION_TYPE_SELL)
      return(current_sl <= open_price);

   return(false);
}

double GetPositionReferenceRiskDistance(const long position_type,
                                        const double open_price,
                                        const double current_sl,
                                        const double current_tp,
                                        const double fallback_atr_value)
{
   if(open_price <= 0.0)
      return(0.0);

   double distance = 0.0;
   if(current_sl > 0.0)
   {
      if(!IsPositionSecured(position_type, open_price, current_sl))
         distance = MathAbs(open_price - current_sl);
   }

   if(distance <= 0.0 && current_tp > 0.0 && InpTakeProfitRewardRisk > 0.0)
      distance = MathAbs(current_tp - open_price) / InpTakeProfitRewardRisk;

   if(distance <= 0.0 && fallback_atr_value > 0.0)
      distance = fallback_atr_value * InpStopLossATR;

   return(distance);
}

TradeSignal SignalFromExitDealType(const ENUM_DEAL_TYPE deal_type)
{
   if(deal_type == DEAL_TYPE_SELL)
      return(SIGNAL_BUY);

   if(deal_type == DEAL_TYPE_BUY)
      return(SIGNAL_SELL);

   return(SIGNAL_NONE);
}

void RegisterStopLossCooldown(const ulong deal_ticket)
{
   if(InpStopLossCooldownBars <= 0)
      return;

   ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
      return;

   ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(deal_ticket, DEAL_REASON);
   if(reason != DEAL_REASON_SL)
      return;

   TradeSignal stopped_signal = SignalFromExitDealType((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE));
   if(stopped_signal == SIGNAL_NONE)
      return;

   datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
   if(stopped_signal == SIGNAL_BUY)
      last_long_stop_loss_time = deal_time;
   else if(stopped_signal == SIGNAL_SELL)
      last_short_stop_loss_time = deal_time;

   LogVerbose("Registered " + SignalToText(stopped_signal) +
              " stop-loss cooldown at " +
              TimeToString(deal_time, TIME_DATE | TIME_SECONDS) +
              ".");
}

void RestoreStopLossCooldownState()
{
   last_long_stop_loss_time = 0;
   last_short_stop_loss_time = 0;

   if(InpStopLossCooldownBars <= 0)
      return;

   if(!HistorySelect(0, TimeCurrent()))
      return;

   for(int i = HistoryDealsTotal() - 1; i >= 0; --i)
   {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket == 0)
         continue;

      if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != _Symbol)
         continue;

      ulong magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      if(magic != InpMagicNumber)
         continue;

      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(deal_ticket, DEAL_REASON);
      if(reason != DEAL_REASON_SL)
         continue;

      TradeSignal stopped_signal = SignalFromExitDealType((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE));
      if(stopped_signal == SIGNAL_BUY && last_long_stop_loss_time == 0)
         last_long_stop_loss_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
      else if(stopped_signal == SIGNAL_SELL && last_short_stop_loss_time == 0)
         last_short_stop_loss_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);

      if(last_long_stop_loss_time > 0 && last_short_stop_loss_time > 0)
         break;
   }
}

bool IsStopLossCooldownActive(const TradeSignal signal, int &bars_remaining)
{
   bars_remaining = 0;

   if(InpStopLossCooldownBars <= 0)
      return(false);

   datetime last_stop_time = 0;
   if(signal == SIGNAL_BUY)
      last_stop_time = last_long_stop_loss_time;
   else if(signal == SIGNAL_SELL)
      last_stop_time = last_short_stop_loss_time;

   if(last_stop_time <= 0)
      return(false);

   int bars_since_stop = iBarShift(_Symbol, InpSignalTimeframe, last_stop_time, false);
   if(bars_since_stop < 0)
      return(false);

   if(bars_since_stop <= InpStopLossCooldownBars)
   {
      bars_remaining = InpStopLossCooldownBars - bars_since_stop + 1;
      return(true);
   }

   return(false);
}

bool IsPositionEligibleForAddOn(const long position_type,
                                const double open_price,
                                const double current_sl)
{
   if(IsPositionSecured(position_type, open_price, current_sl))
      return(true);

   double risk_distance = GetPositionReferenceRiskDistance(position_type,
                                                           open_price,
                                                           current_sl,
                                                           PositionGetDouble(POSITION_TP),
                                                           GetRiskReferenceATR(0));
   if(risk_distance <= 0.0)
      return(false);

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return(false);

   double profit_distance = 0.0;
   if(position_type == POSITION_TYPE_BUY)
      profit_distance = tick.bid - open_price;
   else if(position_type == POSITION_TYPE_SELL)
      profit_distance = open_price - tick.ask;

   return(profit_distance >= risk_distance * InpAddOnMinProfitR);
}

bool CanOpenForSignal(const TradeSignal signal)
{
   int same_direction_count = 0;
   int opposite_direction_count = 0;
   bool all_same_direction_positions_eligible = true;

   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(magic != InpMagicNumber)
         continue;

      long position_type = PositionGetInteger(POSITION_TYPE);
      TradeSignal position_signal = SIGNAL_NONE;
      if(position_type == POSITION_TYPE_BUY)
         position_signal = SIGNAL_BUY;
      else if(position_type == POSITION_TYPE_SELL)
         position_signal = SIGNAL_SELL;

      if(position_signal == signal)
      {
         same_direction_count++;

         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double current_sl = PositionGetDouble(POSITION_SL);
         if(!IsPositionEligibleForAddOn(position_type, open_price, current_sl))
            all_same_direction_positions_eligible = false;
      }
      else if(position_signal != SIGNAL_NONE)
      {
         opposite_direction_count++;
      }
   }

   if(opposite_direction_count > 0)
   {
      LogVerbose("Skipping " + SignalToText(signal) + ": opposite strategy position already open.");
      return(false);
   }

   if(same_direction_count == 0)
      return(true);

   if(!InpAllowAddOnEntry)
   {
      LogVerbose("Skipping " + SignalToText(signal) + ": add-on entries are disabled.");
      return(false);
   }

   if(same_direction_count >= InpMaxPositionsPerDirection)
   {
      LogVerbose("Skipping " + SignalToText(signal) + ": max same-direction positions reached.");
      return(false);
   }

   if(!all_same_direction_positions_eligible)
   {
      LogVerbose("Skipping " + SignalToText(signal) + ": add-on requires existing position to be secured or floating profit threshold met.");
      return(false);
   }

   return(true);
}

double GetProfitLockStopPrice(const long position_type,
                              const double open_price,
                              const double risk_distance,
                              const double target_profit_r)
{
   if(open_price <= 0.0 || risk_distance <= 0.0 || target_profit_r <= 0.0)
      return(0.0);

   double price_distance = risk_distance * target_profit_r;
   if(price_distance <= 0.0)
      return(0.0);

   if(position_type == POSITION_TYPE_BUY)
      return(NormalizePrice(open_price + price_distance));

   if(position_type == POSITION_TYPE_SELL)
      return(NormalizePrice(open_price - price_distance));

   return(0.0);
}

double CalculatePositionSize(const double stop_distance,
                             bool &used_min_volume_fallback,
                             double &effective_risk_percent)
{
   return(CalculatePositionSizeForRisk(stop_distance,
                                       InpRiskPerTradePercent,
                                       used_min_volume_fallback,
                                       effective_risk_percent));
}

double CalculatePositionSizeForRisk(const double stop_distance,
                                    const double risk_percent,
                                    bool &used_min_volume_fallback,
                                    double &effective_risk_percent)
{
   used_min_volume_fallback = false;
   effective_risk_percent = 0.0;

   if(stop_distance <= 0.0)
      return(0.0);

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
      return(0.0);

   double risk_money = equity * (risk_percent / 100.0);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   if(tick_size <= 0.0 || tick_value <= 0.0)
      return(0.0);

   double money_per_lot = (stop_distance / tick_size) * tick_value;
   if(money_per_lot <= 0.0)
      return(0.0);

   double raw_volume = risk_money / money_per_lot;
   double normalized_volume = NormalizeVolume(raw_volume);
   if(normalized_volume > 0.0)
   {
      effective_risk_percent = risk_percent;
      return(normalized_volume);
   }

   if(!InpUseMinVolumeFallback)
      return(0.0);

   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(min_volume <= 0.0 || max_volume <= 0.0 || step <= 0.0)
      return(0.0);

   double fallback_volume = NormalizeDouble(min_volume, VolumeDigits(step));
   if(fallback_volume > max_volume)
      return(0.0);

   double fallback_risk_money = money_per_lot * fallback_volume;
   effective_risk_percent = (fallback_risk_money / equity) * 100.0;
   if(InpMaxFallbackRiskPercent > 0.0 && effective_risk_percent > InpMaxFallbackRiskPercent)
      return(0.0);

   used_min_volume_fallback = true;
   return(fallback_volume);
}

void LogPositionSizeDiagnostic(const double risk_atr_value,
                               const double stop_distance,
                               const double effective_risk_percent)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_money = (equity > 0.0 ? equity * (InpRiskPerTradePercent / 100.0) : 0.0);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int volume_digits = (volume_step > 0.0 ? VolumeDigits(volume_step) : 2);

   double money_per_lot = 0.0;
   double raw_volume = 0.0;
   double min_volume_risk_money = 0.0;
   double min_volume_risk_percent = 0.0;
   double normalized_raw_volume = 0.0;

   if(stop_distance > 0.0 && tick_size > 0.0 && tick_value > 0.0)
   {
      money_per_lot = (stop_distance / tick_size) * tick_value;
      if(money_per_lot > 0.0)
      {
         raw_volume = risk_money / money_per_lot;
         normalized_raw_volume = NormalizeVolume(raw_volume);
         if(min_volume > 0.0)
         {
            min_volume_risk_money = money_per_lot * min_volume;
            if(equity > 0.0)
               min_volume_risk_percent = (min_volume_risk_money / equity) * 100.0;
         }
      }
   }

   LogVerbose("Position sizing diagnostic: balance=" +
              DoubleToString(balance, 2) +
              ", equity=" +
              DoubleToString(equity, 2) +
              ", risk_percent=" +
              DoubleToString(InpRiskPerTradePercent, 2) +
              ", risk_money=" +
              DoubleToString(risk_money, 2) +
              ", risk_atr_value=" +
              DoubleToString(risk_atr_value, _Digits) +
              ", stop_atr_mult=" +
              DoubleToString(InpStopLossATR, 2) +
              ", stop_distance=" +
              DoubleToString(stop_distance, _Digits) +
              ", tick_size=" +
              DoubleToString(tick_size, _Digits) +
              ", tick_value=" +
              DoubleToString(tick_value, 4) +
              ", money_per_lot=" +
              DoubleToString(money_per_lot, 2) +
              ", raw_volume=" +
              DoubleToString(raw_volume, volume_digits + 2) +
              ", normalized_raw_volume=" +
              DoubleToString(normalized_raw_volume, volume_digits) +
              ", min_volume=" +
              DoubleToString(min_volume, volume_digits) +
              ", max_volume=" +
              DoubleToString(max_volume, volume_digits) +
              ", volume_step=" +
              DoubleToString(volume_step, volume_digits) +
              ", min_volume_risk_money=" +
              DoubleToString(min_volume_risk_money, 2) +
              ", min_volume_risk_percent=" +
              DoubleToString(min_volume_risk_percent, 2) +
              ", fallback_cap_percent=" +
              DoubleToString(InpMaxFallbackRiskPercent, 2) +
              ", effective_risk_percent=" +
              DoubleToString(effective_risk_percent, 2) +
              ", min_volume_fallback=" +
              BoolToText(InpUseMinVolumeFallback));
}

double NormalizeVolume(const double raw_volume)
{
   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(step <= 0.0 || max_volume <= 0.0)
      return(0.0);

   double adjusted = MathFloor(raw_volume / step) * step;
   if(adjusted < min_volume)
      return(0.0);
   if(adjusted > max_volume)
      adjusted = max_volume;

   return(NormalizeDouble(adjusted, VolumeDigits(step)));
}

int VolumeDigits(const double step)
{
   int digits = 0;
   double value = step;
   while(digits < 8 && MathRound(value) != value)
   {
      value *= 10.0;
      digits++;
   }
   return(digits);
}

double NormalizePrice(const double price)
{
   return(NormalizeDouble(price, _Digits));
}

double GetIndicatorValue(const int handle, const int shift)
{
   double values[];
   ArrayResize(values, 1);
   ArraySetAsSeries(values, true);
   if(CopyBuffer(handle, 0, shift, 1, values) < 1)
      return(0.0);

   return(values[0]);
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

   double fast_ma = GetIndicatorValue(fast_ma_handle, 1);
   double slow_ma = GetIndicatorValue(slow_ma_handle, 1);
   double slow_ma_previous = GetIndicatorValue(slow_ma_handle, 2);
   double rsi_value = GetIndicatorValue(rsi_handle, 1);
   double atr_value = GetIndicatorValue(atr_handle, 1);
   double htf_slow_ma = 0.0;
   double htf_baseline_ma = 0.0;
   if(InpUseHigherTimeframeTrendFilter && trend_slow_ma_handle != INVALID_HANDLE)
      htf_slow_ma = GetIndicatorValue(trend_slow_ma_handle, 1);
   if(InpUseHigherTimeframeTrendFilter && trend_baseline_ma_handle != INVALID_HANDLE)
      htf_baseline_ma = GetIndicatorValue(trend_baseline_ma_handle, 1);

   double ema_slope = slow_ma - slow_ma_previous;
   double ma_spread_atr = 0.0;
   double slow_slope_atr = 0.0;
   if(atr_value > 0.0)
   {
      ma_spread_atr = MathAbs(fast_ma - slow_ma) / atr_value;
      slow_slope_atr = MathAbs(ema_slope) / atr_value;
   }

   TradeSignal htf_bias = GetHigherTimeframeTrendBias();
   string calendar_blocked = "false";
   if(reason == "CALENDAR_BLOCKED")
      calendar_blocked = "true";

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
             EnumToString(InpTrendFilterTimeframe),
             action,
             SignalToText(signal),
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
             SignalToText(htf_bias),
             calendar_blocked,
             DoubleToString(volume, 2),
             DoubleToString(sl, _Digits),
             DoubleToString(tp, _Digits),
             UInt64ToText(order_ticket),
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

   datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
   FileWrite(handle,
             UInt64ToText(deal_ticket),
             TimeToString(deal_time, TIME_DATE | TIME_SECONDS),
             HistoryDealGetString(deal_ticket, DEAL_SYMBOL),
             DealEntryToText((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY)),
             DealTypeToText((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE)),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_VOLUME), 2),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_PRICE), _Digits),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_PROFIT), 2),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION), 2),
             DoubleToString(HistoryDealGetDouble(deal_ticket, DEAL_SWAP), 2),
             IntegerToString((int)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC)),
             UInt64ToText((ulong)HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID)),
             HistoryDealGetString(deal_ticket, DEAL_COMMENT),
             DealReasonToText((ENUM_DEAL_REASON)HistoryDealGetInteger(deal_ticket, DEAL_REASON)));

   FileClose(handle);
}

string DealEntryToText(const ENUM_DEAL_ENTRY entry)
{
   switch(entry)
   {
      case DEAL_ENTRY_IN:     return("IN");
      case DEAL_ENTRY_OUT:    return("OUT");
      case DEAL_ENTRY_INOUT:  return("INOUT");
      case DEAL_ENTRY_OUT_BY: return("OUT_BY");
   }
   return("UNKNOWN");
}

string DealTypeToText(const ENUM_DEAL_TYPE deal_type)
{
   switch(deal_type)
   {
      case DEAL_TYPE_BUY:             return("BUY");
      case DEAL_TYPE_SELL:            return("SELL");
      case DEAL_TYPE_BALANCE:         return("BALANCE");
      case DEAL_TYPE_CREDIT:          return("CREDIT");
      case DEAL_TYPE_CHARGE:          return("CHARGE");
      case DEAL_TYPE_CORRECTION:      return("CORRECTION");
      case DEAL_TYPE_BONUS:           return("BONUS");
      case DEAL_TYPE_COMMISSION:      return("COMMISSION");
      case DEAL_TYPE_COMMISSION_DAILY:return("COMMISSION_DAILY");
      case DEAL_TYPE_COMMISSION_MONTHLY:return("COMMISSION_MONTHLY");
      case DEAL_TYPE_COMMISSION_AGENT_DAILY:return("COMMISSION_AGENT_DAILY");
      case DEAL_TYPE_COMMISSION_AGENT_MONTHLY:return("COMMISSION_AGENT_MONTHLY");
      case DEAL_TYPE_INTEREST:        return("INTEREST");
      case DEAL_TYPE_BUY_CANCELED:    return("BUY_CANCELED");
      case DEAL_TYPE_SELL_CANCELED:   return("SELL_CANCELED");
      case DEAL_DIVIDEND:             return("DIVIDEND");
      case DEAL_DIVIDEND_FRANKED:     return("DIVIDEND_FRANKED");
      case DEAL_TAX:                  return("TAX");
   }
   return("UNKNOWN");
}

string DealReasonToText(const ENUM_DEAL_REASON reason)
{
   switch(reason)
   {
      case DEAL_REASON_CLIENT:   return("CLIENT");
      case DEAL_REASON_MOBILE:   return("MOBILE");
      case DEAL_REASON_WEB:      return("WEB");
      case DEAL_REASON_EXPERT:   return("EXPERT");
      case DEAL_REASON_SL:       return("SL");
      case DEAL_REASON_TP:       return("TP");
      case DEAL_REASON_SO:       return("SO");
      case DEAL_REASON_ROLLOVER: return("ROLLOVER");
      case DEAL_REASON_VMARGIN:  return("VMARGIN");
      case DEAL_REASON_SPLIT:    return("SPLIT");
   }
   return("UNKNOWN");
}

string UInt64ToText(const ulong value)
{
   return(StringFormat("%I64u", value));
}

string SignalToText(const TradeSignal signal)
{
   switch(signal)
   {
      case SIGNAL_BUY:  return("BUY");
      case SIGNAL_SELL: return("SELL");
      default:          return("NONE");
   }
}

string BoolToText(const bool value)
{
   return(value ? "true" : "false");
}

string AppendListText(const string current, const string item)
{
   if(current == "")
      return(item);

   return(current + "|" + item);
}

string AccountTradeModeToText(const ENUM_ACCOUNT_TRADE_MODE mode)
{
   switch(mode)
   {
      case ACCOUNT_TRADE_MODE_DEMO:    return("DEMO");
      case ACCOUNT_TRADE_MODE_CONTEST: return("CONTEST");
      case ACCOUNT_TRADE_MODE_REAL:    return("REAL");
   }

   return("UNKNOWN");
}

string SymbolTradeModeToText(const ENUM_SYMBOL_TRADE_MODE mode)
{
   switch(mode)
   {
      case SYMBOL_TRADE_MODE_DISABLED:  return("DISABLED");
      case SYMBOL_TRADE_MODE_LONGONLY:  return("LONG_ONLY");
      case SYMBOL_TRADE_MODE_SHORTONLY: return("SHORT_ONLY");
      case SYMBOL_TRADE_MODE_CLOSEONLY: return("CLOSE_ONLY");
      case SYMBOL_TRADE_MODE_FULL:      return("FULL");
   }

   return("UNKNOWN");
}

string SymbolExecutionModeToText(const ENUM_SYMBOL_TRADE_EXECUTION mode)
{
   switch(mode)
   {
      case SYMBOL_TRADE_EXECUTION_REQUEST:  return("REQUEST");
      case SYMBOL_TRADE_EXECUTION_INSTANT:  return("INSTANT");
      case SYMBOL_TRADE_EXECUTION_MARKET:   return("MARKET");
      case SYMBOL_TRADE_EXECUTION_EXCHANGE: return("EXCHANGE");
   }

   return("UNKNOWN");
}

string SymbolFillingModeToText(const long filling_mode)
{
   string text = "";
   if((filling_mode & (long)SYMBOL_FILLING_FOK) == (long)SYMBOL_FILLING_FOK)
      text = AppendListText(text, "FOK");
   if((filling_mode & (long)SYMBOL_FILLING_IOC) == (long)SYMBOL_FILLING_IOC)
      text = AppendListText(text, "IOC");

   if(text == "")
      return("none");

   return(text);
}

void LogTradingEnvironment(const string context)
{
   MqlTick tick;
   bool has_tick = SymbolInfoTick(_Symbol, tick);
   double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int volume_digits = (volume_step > 0.0 ? VolumeDigits(volume_step) : 2);
   long trade_mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   long exec_mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_EXEMODE);
   long filling_mode = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   long order_mode = SymbolInfoInteger(_Symbol, SYMBOL_ORDER_MODE);
   long stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freeze_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   long spread_points = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   Print(context,
         ": account_login=", IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)),
         ", account_mode=", AccountTradeModeToText((ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE)),
         ", account_trade_allowed=", BoolToText((bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)),
         ", account_expert_allowed=", BoolToText((bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT)),
         ", terminal_trade_allowed=", BoolToText((bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)),
         ", mql_trade_allowed=", BoolToText((bool)MQLInfoInteger(MQL_TRADE_ALLOWED)));

   Print(context,
         ": symbol=", _Symbol,
         ", selected=", BoolToText((bool)SymbolInfoInteger(_Symbol, SYMBOL_SELECT)),
         ", trade_mode=", SymbolTradeModeToText((ENUM_SYMBOL_TRADE_MODE)trade_mode), "(", IntegerToString(trade_mode), ")",
         ", exec_mode=", SymbolExecutionModeToText((ENUM_SYMBOL_TRADE_EXECUTION)exec_mode), "(", IntegerToString(exec_mode), ")",
         ", filling_mode=", SymbolFillingModeToText(filling_mode), "(", IntegerToString(filling_mode), ")",
         ", order_mode=", IntegerToString(order_mode));

   Print(context,
         ": volume_min=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), volume_digits),
         ", volume_max=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), volume_digits),
         ", volume_step=", DoubleToString(volume_step, volume_digits),
         ", stops_level_points=", IntegerToString(stops_level),
         ", freeze_level_points=", IntegerToString(freeze_level),
         ", spread_points=", IntegerToString(spread_points),
         ", tick_size=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE), _Digits),
         ", tick_value=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE), 2),
         ", contract_size=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE), 2));

   Print(context,
         ": balance=", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
         ", equity=", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2),
         ", margin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2),
         ", margin_free=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2),
         ", leverage=", IntegerToString((long)AccountInfoInteger(ACCOUNT_LEVERAGE)),
         ", bid=", (has_tick ? DoubleToString(tick.bid, _Digits) : "n/a"),
         ", ask=", (has_tick ? DoubleToString(tick.ask, _Digits) : "n/a"));
}

void LogOrderFailure(const string action,
                     const double sl,
                     const double tp,
                     const double risk_distance)
{
   Print(action,
         ": retcode=", IntegerToString((long)trade.ResultRetcode()),
         ", retcode_text=", trade.ResultRetcodeDescription(),
         ", external_retcode=", IntegerToString((long)trade.ResultRetcodeExternal()),
         ", result_comment=", trade.ResultComment(),
         ", request_type=", trade.RequestTypeDescription(),
         ", request_filling=", trade.RequestTypeFillingDescription(),
         ", request_volume=", DoubleToString(trade.RequestVolume(), 2),
         ", request_price=", DoubleToString(trade.RequestPrice(), _Digits),
         ", sl=", DoubleToString(sl, _Digits),
         ", tp=", DoubleToString(tp, _Digits),
         ", risk_distance=", DoubleToString(risk_distance, _Digits));

   LogTradingEnvironment(action + " environment");
}

void LogVerbose(const string message)
{
   if(InpVerboseLogs)
      Print(message);
}

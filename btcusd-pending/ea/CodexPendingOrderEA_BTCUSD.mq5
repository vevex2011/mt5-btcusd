#property copyright "Codex Autotrade"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

enum TradeSignal
{
   SIGNAL_NONE = 0,
   SIGNAL_BUY = 1,
   SIGNAL_SELL = -1
};

input string          InpTargetSymbol = "BTCUSD";
input bool            InpEnforceTargetSymbol = true;
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_M30;
input ENUM_TIMEFRAMES InpTrendTimeframe = PERIOD_H4;

input bool            InpDryRun = false;

input bool            InpUseModelDirectTrading = true;
input string          InpModelRecommendationFile = "codex-edge-model\\edge_recommendations.json";
input bool            InpUseModelRecommendationFilter = true;
input bool            InpAllowTradeWhenModelMissing = false;
input int             InpModelMaxAgeSeconds = 86400;
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
input bool            InpModelDirectUseTopRule = true;
input bool            InpModelDirectPreferDeepModel = true;
input bool            InpModelDirectRequireDeepModel = false;
input double          InpDeepModelMinProbability = 0.58;
input double          InpDeepModelMinConfidence = 0.10;
input bool            InpModelDirectRequireDailyDirection = false;
input int             InpModelDirectMinSamples = 50;
input double          InpModelDirectMinScore = 1.50;
input bool            InpModelRequirePositiveNetExpectancy = true;
input double          InpModelMinNetExpectancyATR = 0.02;
input bool            InpUseModelExecutionPlan = true;
input bool            InpModelExecutionPreferDeepModel = true;
input double          InpModelExecutionMinRiskPercent = 0.05;
input double          InpModelExecutionMaxRiskPercent = 0.80;
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

input ulong           InpModelDirectMagicNumber = 2026050715;

input int             InpFastMAPeriod = 20;
input int             InpSlowMAPeriod = 50;
input int             InpTrendBaselineMAPeriod = 200;
input int             InpRSIPeriod = 14;
input int             InpATRPeriod = 14;
input int             InpTrendConfirmBars = 2;

input double          InpRiskPerOrderPercent = 0.20;
input bool            InpUseMinVolumeFallback = true;
input double          InpMaxFallbackRiskPercent = 4.00;
input double          InpStopLossATR = 1.20;
input double          InpTakeProfitRewardRisk = 1.50;
input bool            InpEnableProfitFloorStop = true;
input double          InpProfitFloorArmMoney = 1.00;
input double          InpProfitFloorLockMoney = 0.60;
input double          InpProfitFloorStepMoney = 0.60;
input bool            InpProfitFloorRemoveTakeProfit = true;
input bool            InpEnableMaxLossStop = true;
input int             InpMaxLossStopPoints = 30000;

input int             InpMaxSpreadPoints = 5000;
input double          InpMaxSpreadATR = 0.08;
input int             InpDeviationPoints = 50;

input string          InpLogFolder = "codex-mt5-btcusd-pending";
input bool            InpVerboseLogs = true;
input bool            InpTelegramEnabled = true;
input string          InpTelegramConfigFile = "telegram.info";
input string          InpTelegramApiURL = "";
input string          InpTelegramEnv = "";
input string          InpTelegramBotToken = "";
input string          InpTelegramChatID = "";
input int             InpTelegramTimeoutMs = 5000;

#include "CodexModelRecommendations.mqh"

const int SIGNAL_LOOKBACK_BARS = 12;

const ulong LEGACY_LIMIT_MAGIC_NUMBER = 2026050711;
const ulong LEGACY_STOP_MAGIC_NUMBER = 2026050712;
const ulong LEGACY_STOP_LIMIT_MAGIC_NUMBER = 2026050713;
const ulong LEGACY_CHART_LINE_MAGIC_NUMBER = 2026050714;

CTrade trade;

int fast_ma_handle = INVALID_HANDLE;
int slow_ma_handle = INVALID_HANDLE;
int rsi_handle = INVALID_HANDLE;
int atr_handle = INVALID_HANDLE;
int trend_slow_ma_handle = INVALID_HANDLE;
int trend_baseline_ma_handle = INVALID_HANDLE;
int trend_atr_handle = INVALID_HANDLE;
bool use_manual_indicator_values = false;

datetime last_signal_bar_time = 0;
bool warned_symbol_mismatch = false;
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
         ", dry_run=", BoolToText(InpDryRun),
         ", log_folder=", InpLogFolder,
         ", telegram=", BoolToText(InpTelegramEnabled),
         ", telegram_env=", (telegram_env == "" ? "-" : telegram_env),
         ", telegram_token=", (telegram_bot_token == "" ? "MISSING" : "SET"),
         ", telegram_chat_id=", (telegram_chat_id == "" ? "MISSING" : "SET"),
         ", entry_mode=MODEL_DIRECT_ONLY");
   Print("Risk guard settings: profit_floor_stop=", BoolToText(InpEnableProfitFloorStop),
         ", profit_floor_arm=", DoubleToString(InpProfitFloorArmMoney, 2),
         ", profit_floor_lock_money=", DoubleToString(InpProfitFloorLockMoney, 2),
         ", profit_floor_step_money=", DoubleToString(InpProfitFloorStepMoney, 2),
         ", profit_floor_remove_tp=", BoolToText(InpProfitFloorRemoveTakeProfit),
         ", max_loss_stop=", BoolToText(InpEnableMaxLossStop),
         ", max_loss_stop_points=", IntegerToString(InpMaxLossStopPoints),
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

   if(!InpUseModelDirectTrading)
   {
      LogVerbose("Skipping: model-direct-only mode requires model direct trading to be enabled.");
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
      PeriodSeconds(InpTrendTimeframe) <= 0)
   {
      Print("Invalid timeframe input.");
      return false;
   }

   if(InpFastMAPeriod >= InpSlowMAPeriod)
   {
      Print("Invalid MA periods: fast EMA must be lower than slow EMA.");
      return false;
   }

   if(InpTrendConfirmBars < 1)
   {
      Print("Invalid trend confirmation input.");
      return false;
   }

   if(InpRiskPerOrderPercent <= 0.0 || InpStopLossATR <= 0.0 || InpTakeProfitRewardRisk <= 0.0 ||
      InpProfitFloorArmMoney <= 0.0 || InpProfitFloorLockMoney < 0.0 ||
      InpProfitFloorLockMoney >= InpProfitFloorArmMoney ||
      InpProfitFloorStepMoney <= 0.0 ||
      InpMaxLossStopPoints < 1)
   {
      Print("Invalid risk input.");
      return false;
   }

   if(InpUseModelDirectTrading &&
      (InpModelRecommendationFile == "" ||
       InpModelMaxAgeSeconds < 1 ||
       InpModelDirectMinSamples < 1 ||
       InpModelDirectMinScore < 0.0 ||
       InpMaxModelDirectPositionsPerDirection < 1 ||
       InpModelLowFrequencyCooldownMinutes < 0 ||
       InpModelNormalFrequencyCooldownMinutes < 0 ||
       InpModelHighFrequencyCooldownMinutes < 0))
   {
      Print("Invalid model direct trading input.");
      return false;
   }

   if(InpModelDirectMagicNumber == 0 ||
      InpModelDirectMagicNumber == LEGACY_LIMIT_MAGIC_NUMBER ||
      InpModelDirectMagicNumber == LEGACY_STOP_MAGIC_NUMBER ||
      InpModelDirectMagicNumber == LEGACY_STOP_LIMIT_MAGIC_NUMBER ||
      InpModelDirectMagicNumber == LEGACY_CHART_LINE_MAGIC_NUMBER)
   {
      Print("Model direct magic number must be non-zero and distinct from legacy pending-order magic numbers.");
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
   const int bars_needed = SIGNAL_LOOKBACK_BARS;
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

   const int bars_needed = SIGNAL_LOOKBACK_BARS;

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
      bullish = bullish && trend_rates[i].close > trend_slow_ma[i] &&
                trend_slow_ma[i] > trend_baseline_ma[i];
      bearish = bearish && trend_rates[i].close < trend_slow_ma[i] &&
                trend_slow_ma[i] < trend_baseline_ma[i];
   }

   if(bullish)
      return SIGNAL_BUY;
   if(bearish)
      return SIGNAL_SELL;
   return SIGNAL_NONE;
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
   return true;
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

string TrimString(string value)
{
   StringTrimLeft(value);
   StringTrimRight(value);
   return value;
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

void RemoveAllManagedPendingOrders()
{
   const int orders_total = OrdersTotal();
   for(int i = orders_total - 1; i >= 0; i--)
   {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)OrderGetInteger(ORDER_MAGIC);
      if(!IsManagedMagic(magic))
         continue;

      const ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsManagedPendingType(type))
         continue;

      if(InpDryRun)
      {
         LogVerbose("Dry run: would remove managed pending order ticket=" +
                    UInt64ToText(ticket) +
                    ", type=" + OrderTypeToText(type) +
                    ", magic=" + IntegerToString((long)magic));
         continue;
      }

      trade.SetExpertMagicNumber(magic);
      if(!trade.OrderDelete(ticket))
      {
         Print("Failed to remove managed pending order. ticket=", UInt64ToText(ticket),
               ", type=", OrderTypeToText(type),
               ", magic=", IntegerToString((long)magic),
               ", retcode=", IntegerToString((int)trade.ResultRetcode()),
               ", description=", trade.ResultRetcodeDescription(),
               ", last_error=", GetLastError());
      }
   }

   trade.SetExpertMagicNumber(InpModelDirectMagicNumber);
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
   const double volume = CalculatePositionSizeForRisk(stop_distance,
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

double NormalizeVolumeFloor(const double volume, const double volume_step)
{
   if(volume_step <= 0.0)
      return 0.0;
   return MathFloor(volume / volume_step) * volume_step;
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
   return magic == LEGACY_LIMIT_MAGIC_NUMBER ||
          magic == LEGACY_STOP_MAGIC_NUMBER ||
          magic == LEGACY_STOP_LIMIT_MAGIC_NUMBER ||
          magic == LEGACY_CHART_LINE_MAGIC_NUMBER ||
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

double NormalizePrice(const double price)
{
   return NormalizeDouble(price, _Digits);
}

double NormalizePriceDistance(const double distance)
{
   return MathMax(NormalizeDouble(distance, _Digits), _Point);
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

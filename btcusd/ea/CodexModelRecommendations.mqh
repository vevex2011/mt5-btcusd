#property strict

struct CodexModelRecommendation
{
   bool     available;
   datetime generated_at;
   string   direction_bias;
   string   frequency_bias;
   double   direction_confidence;
   bool     signal_rule_found;
   double   signal_score;
   double   signal_net_expectancy_atr;
   int      signal_samples;
   double   signal_stop_atr;
   double   signal_target_atr;
   int      signal_hold_bars;
   double   signal_trail_start_atr;
   double   signal_trail_distance_atr;
   bool     top_rule_found;
   string   top_direction;
   double   top_score;
   double   top_net_expectancy_atr;
   int      top_samples;
   double   top_stop_atr;
   double   top_target_atr;
   int      top_hold_bars;
   double   top_trail_start_atr;
   double   top_trail_distance_atr;
   bool     aligned_rule_found;
   string   aligned_direction;
   double   aligned_score;
   double   aligned_net_expectancy_atr;
   int      aligned_samples;
   double   aligned_stop_atr;
   double   aligned_target_atr;
   int      aligned_hold_bars;
   double   aligned_trail_start_atr;
   double   aligned_trail_distance_atr;
   bool     execution_plan_found;
   double   execution_net_expectancy_atr;
   double   execution_estimated_cost_atr;
   double   execution_risk_percent;
   double   execution_stop_atr;
   double   execution_target_atr;
   int      execution_hold_bars;
   double   execution_trail_start_atr;
   double   execution_trail_distance_atr;
   int      execution_cooldown_minutes;
   int      execution_max_positions_per_direction;
   bool     deep_model_found;
   string   deep_best_action;
   string   deep_best_direction;
   string   deep_best_source_model;
   string   deep_best_run_id;
   string   deep_best_candle_time;
   double   deep_best_probability;
   double   deep_best_confidence;
   double   deep_best_net_expectancy_atr;
   double   deep_best_estimated_cost_atr;
   double   deep_best_net_win_rate;
   double   deep_best_stop_atr;
   double   deep_best_target_atr;
   int      deep_best_hold_bars;
   double   deep_best_trail_start_atr;
   double   deep_best_trail_distance_atr;
   double   deep_best_rule_score;
   int      deep_best_rule_samples;
};

datetime codex_model_last_missing_warning = 0;

bool IsModelNetExpectancyBlocked(const double net_expectancy_atr,
                                 const string source,
                                 string &reason)
{
   if(!InpModelRequirePositiveNetExpectancy)
      return(false);
   if(net_expectancy_atr >= InpModelMinNetExpectancyATR)
      return(false);

   reason = "model net expectancy too low: source=" + source +
            ", net_expectancy_atr=" + DoubleToString(net_expectancy_atr, 4) +
            ", min_net_expectancy_atr=" + DoubleToString(InpModelMinNetExpectancyATR, 4);
   return(true);
}

bool IsModelRecommendationBlocked(const TradeSignal signal, string &reason)
{
   reason = "";
   if(!InpUseModelRecommendationFilter)
      return(false);

   CodexModelRecommendation recommendation;
   if(!LoadModelRecommendation(signal, recommendation, reason))
      return(!InpAllowTradeWhenModelMissing);

   if(InpModelUseFrequencyThrottle && IsModelFrequencyThrottled(signal,
                                                                recommendation.frequency_bias,
                                                                reason))
      return(true);

   if(InpModelUseDirectionBias &&
      recommendation.direction_bias != "" &&
      recommendation.direction_bias != "NONE" &&
      recommendation.direction_bias != SignalToText(signal) &&
      recommendation.direction_confidence >= InpModelDirectionMinConfidence)
   {
      reason = "daily direction bias=" + recommendation.direction_bias +
               ", confidence=" + DoubleToString(recommendation.direction_confidence, 3) +
               ", min_confidence=" + DoubleToString(InpModelDirectionMinConfidence, 3);
      return(true);
   }

   if(InpModelUseShortRuleScore && recommendation.signal_rule_found)
   {
      if(recommendation.signal_samples < InpModelMinDirectionSamples)
      {
         reason = "model direction rule samples too low: samples=" +
                  IntegerToString(recommendation.signal_samples) +
                  ", min_samples=" + IntegerToString(InpModelMinDirectionSamples);
         return(true);
      }

      if(recommendation.signal_score < InpModelMinDirectionScore)
      {
         reason = "model direction score too low: score=" +
                  DoubleToString(recommendation.signal_score, 3) +
                  ", min_score=" + DoubleToString(InpModelMinDirectionScore, 3);
         return(true);
      }

      if(IsModelNetExpectancyBlocked(recommendation.signal_net_expectancy_atr,
                                     "direction_rule",
                                     reason))
         return(true);
   }

   if(InpModelUseShortRuleScore &&
      InpModelOppositeTopScoreBlock > 0.0 &&
      recommendation.top_rule_found &&
      recommendation.top_direction != "" &&
      recommendation.top_direction != SignalToText(signal) &&
      recommendation.top_score >= InpModelOppositeTopScoreBlock &&
      (!recommendation.signal_rule_found ||
       recommendation.signal_score < InpModelMinDirectionScore))
   {
      reason = "opposite top model rule is stronger: top_direction=" +
               recommendation.top_direction +
               ", top_score=" + DoubleToString(recommendation.top_score, 3) +
               ", signal_score=" + DoubleToString(recommendation.signal_score, 3);
      return(true);
   }

   LogVerbose("Model recommendation pass: bias=" +
              recommendation.direction_bias +
              ", freq=" + recommendation.frequency_bias +
              ", confidence=" + DoubleToString(recommendation.direction_confidence, 3) +
              ", signal_score=" + DoubleToString(recommendation.signal_score, 3) +
              ", samples=" + IntegerToString(recommendation.signal_samples) +
              ", deep_action=" + recommendation.deep_best_action +
              ", deep_probability=" + DoubleToString(recommendation.deep_best_probability, 3));
   return(false);
}

void MarkModelRecommendationEntry(const TradeSignal signal)
{
   if((!InpUseModelRecommendationFilter && !InpUseModelDirectTrading) ||
      !InpModelUseFrequencyThrottle)
      return;

   GlobalVariableSet(ModelLastEntryKey(signal), (double)TimeCurrent());
}

bool GetModelDirectSignal(TradeSignal &signal, string &reason)
{
   signal = SIGNAL_NONE;
   reason = "";

   if(!InpUseModelDirectTrading)
   {
      reason = "model direct trading is disabled";
      return(false);
   }

   CodexModelRecommendation recommendation;
   string symbol_object = "";
   if(!LoadModelRecommendationCore(recommendation, symbol_object, reason))
      return(false);

   if(InpModelDirectPreferDeepModel && recommendation.deep_model_found)
   {
      string deep_action = recommendation.deep_best_action;
      StringToUpper(deep_action);

      if(deep_action == "BUY" || deep_action == "SELL")
      {
         if(recommendation.deep_best_probability < InpDeepModelMinProbability)
         {
            reason = "deep model probability too low: probability=" +
                     DoubleToString(recommendation.deep_best_probability, 3) +
                     ", min_probability=" + DoubleToString(InpDeepModelMinProbability, 3);
            if(InpModelDirectRequireDeepModel)
               return(false);
         }
         else if(recommendation.deep_best_confidence < InpDeepModelMinConfidence)
         {
            reason = "deep model confidence too low: confidence=" +
                     DoubleToString(recommendation.deep_best_confidence, 3) +
                     ", min_confidence=" + DoubleToString(InpDeepModelMinConfidence, 3);
            if(InpModelDirectRequireDeepModel)
               return(false);
         }
         else if(IsModelNetExpectancyBlocked(recommendation.deep_best_net_expectancy_atr,
                                             "deep_model",
                                             reason))
         {
            if(InpModelDirectRequireDeepModel)
               return(false);
         }
         else
         {
            signal = ModelSignalFromText(deep_action);
            if(signal == SIGNAL_NONE)
            {
               reason = "deep model action is not tradable: action=" + deep_action;
               return(false);
            }

            if(InpModelUseFrequencyThrottle &&
               IsModelFrequencyThrottled(signal, recommendation.frequency_bias, reason))
            {
               signal = SIGNAL_NONE;
               return(false);
            }

            reason = "source=deep_model" +
                     ", action=" + deep_action +
                     ", probability=" + DoubleToString(recommendation.deep_best_probability, 3) +
                     ", confidence=" + DoubleToString(recommendation.deep_best_confidence, 3) +
                     ", net_expectancy_atr=" + DoubleToString(recommendation.deep_best_net_expectancy_atr, 4) +
                     ", rule_score=" + DoubleToString(recommendation.deep_best_rule_score, 3) +
                     ", rule_samples=" + IntegerToString(recommendation.deep_best_rule_samples) +
                     ", freq=" + recommendation.frequency_bias +
                     ", daily_bias=" + recommendation.direction_bias +
                     ", daily_confidence=" + DoubleToString(recommendation.direction_confidence, 3);
            return(true);
         }
      }
      else if(InpModelDirectRequireDeepModel)
      {
         reason = "deep model has no actionable direction: action=" + recommendation.deep_best_action;
         return(false);
      }
   }

   string selected_direction = "";
   string selected_source = "";
   double selected_score = 0.0;
   double selected_net_expectancy_atr = 0.0;
   int selected_samples = 0;

   if(InpModelDirectUseTopRule && recommendation.top_rule_found)
   {
      selected_direction = recommendation.top_direction;
      selected_score = recommendation.top_score;
      selected_net_expectancy_atr = recommendation.top_net_expectancy_atr;
      selected_samples = recommendation.top_samples;
      selected_source = "top_short_rule";
   }

   if(selected_direction == "" && recommendation.aligned_rule_found)
   {
      selected_direction = recommendation.aligned_direction;
      selected_score = recommendation.aligned_score;
      selected_net_expectancy_atr = recommendation.aligned_net_expectancy_atr;
      selected_samples = recommendation.aligned_samples;
      selected_source = "aligned_short_rule";
   }

   if(selected_direction == "" && recommendation.top_rule_found)
   {
      selected_direction = recommendation.top_direction;
      selected_score = recommendation.top_score;
      selected_net_expectancy_atr = recommendation.top_net_expectancy_atr;
      selected_samples = recommendation.top_samples;
      selected_source = "top_short_rule";
   }

   if(selected_direction == "" || selected_direction == "NONE")
   {
      reason = "model direct signal missing direction";
      return(false);
   }

   signal = ModelSignalFromText(selected_direction);
   if(signal == SIGNAL_NONE)
   {
      reason = "model direct direction is not tradable: direction=" + selected_direction;
      return(false);
   }

   if(selected_samples < InpModelDirectMinSamples)
   {
      reason = "model direct rule samples too low: source=" + selected_source +
               ", samples=" + IntegerToString(selected_samples) +
               ", min_samples=" + IntegerToString(InpModelDirectMinSamples);
      signal = SIGNAL_NONE;
      return(false);
   }

   if(selected_score < InpModelDirectMinScore)
   {
      reason = "model direct score too low: source=" + selected_source +
               ", score=" + DoubleToString(selected_score, 3) +
               ", min_score=" + DoubleToString(InpModelDirectMinScore, 3);
      signal = SIGNAL_NONE;
      return(false);
   }

   if(IsModelNetExpectancyBlocked(selected_net_expectancy_atr,
                                  selected_source,
                                  reason))
   {
      signal = SIGNAL_NONE;
      return(false);
   }

   if(InpModelDirectRequireDailyDirection &&
      recommendation.direction_bias != "" &&
      recommendation.direction_bias != "NONE" &&
      recommendation.direction_bias != selected_direction &&
      recommendation.direction_confidence >= InpModelDirectionMinConfidence)
   {
      reason = "model direct daily bias mismatch: selected=" + selected_direction +
               ", daily_bias=" + recommendation.direction_bias +
               ", confidence=" + DoubleToString(recommendation.direction_confidence, 3);
      signal = SIGNAL_NONE;
      return(false);
   }

   if(InpModelUseFrequencyThrottle &&
      IsModelFrequencyThrottled(signal, recommendation.frequency_bias, reason))
   {
      signal = SIGNAL_NONE;
      return(false);
   }

   reason = "source=" + selected_source +
            ", direction=" + selected_direction +
            ", score=" + DoubleToString(selected_score, 3) +
            ", net_expectancy_atr=" + DoubleToString(selected_net_expectancy_atr, 4) +
            ", samples=" + IntegerToString(selected_samples) +
            ", freq=" + recommendation.frequency_bias +
            ", daily_bias=" + recommendation.direction_bias +
            ", daily_confidence=" + DoubleToString(recommendation.direction_confidence, 3);
   return(true);
}

bool GetModelSignalLogFields(string &source_model,
                             string &run_id,
                             string &action,
                             string &candle_time,
                             string &frequency_bias,
                             string &direction_bias,
                             double &probability,
                             double &confidence,
                             double &net_expectancy_atr,
                             double &rule_score,
                             int &rule_samples)
{
   source_model = "";
   run_id = "";
   action = "";
   candle_time = "";
   frequency_bias = "";
   direction_bias = "";
   probability = 0.0;
   confidence = 0.0;
   net_expectancy_atr = 0.0;
   rule_score = 0.0;
   rule_samples = 0;

   CodexModelRecommendation recommendation;
   string symbol_object = "";
   string reason = "";
   if(!LoadModelRecommendationCore(recommendation, symbol_object, reason))
      return(false);

   source_model = recommendation.deep_best_source_model;
   run_id = recommendation.deep_best_run_id;
   action = recommendation.deep_best_action;
   candle_time = recommendation.deep_best_candle_time;
   frequency_bias = recommendation.frequency_bias;
   direction_bias = recommendation.direction_bias;
   probability = recommendation.deep_best_probability;
   confidence = recommendation.deep_best_confidence;
   net_expectancy_atr = recommendation.deep_best_net_expectancy_atr;
   rule_score = recommendation.deep_best_rule_score;
   rule_samples = recommendation.deep_best_rule_samples;
   return(recommendation.deep_model_found);
}

bool GetModelExecutionPlan(const TradeSignal signal,
                           double &risk_percent,
                           double &stop_atr,
                           double &target_atr,
                           int &max_positions_per_direction,
                           int &cooldown_minutes,
                           string &reason)
{
   risk_percent = InpRiskPerTradePercent;
   stop_atr = InpStopLossATR;
   target_atr = InpStopLossATR * 1.5;
   max_positions_per_direction = InpMaxPositionsPerDirection;
   cooldown_minutes = 0;
   reason = "";

   if(!InpUseModelExecutionPlan)
   {
      reason = "model execution plan disabled";
      return(false);
   }

   CodexModelRecommendation recommendation;
   string symbol_object = "";
   if(!LoadModelRecommendationCore(recommendation, symbol_object, reason))
      return(false);

   string selected_source = "";
   double selected_score = 0.0;
   double selected_net_expectancy_atr = 0.0;
   int selected_samples = 0;
   double selected_stop_atr = 0.0;
   double selected_target_atr = 0.0;
   int selected_hold_bars = 0;
   double selected_trail_start_atr = 0.0;
   double selected_trail_distance_atr = 0.0;
   SelectModelDirectRuleForSignal(recommendation,
                                  signal,
                                  selected_source,
                                  selected_score,
                                  selected_net_expectancy_atr,
                                  selected_samples,
                                  selected_stop_atr,
                                  selected_target_atr,
                                  selected_hold_bars,
                                  selected_trail_start_atr,
                                  selected_trail_distance_atr);

   const bool use_deep_execution =
      InpModelExecutionPreferDeepModel &&
      recommendation.deep_model_found &&
      recommendation.deep_best_action == SignalToText(signal) &&
      recommendation.deep_best_probability >= InpDeepModelMinProbability &&
      recommendation.deep_best_confidence >= InpDeepModelMinConfidence;

   if(use_deep_execution)
   {
      selected_source = "deep_model";
      selected_score = recommendation.deep_best_probability;
      selected_net_expectancy_atr = recommendation.deep_best_net_expectancy_atr;
      selected_samples = recommendation.deep_best_rule_samples;
      selected_stop_atr = recommendation.deep_best_stop_atr;
      selected_target_atr = recommendation.deep_best_target_atr;
   }
   else if(selected_net_expectancy_atr <= 0.0 && recommendation.execution_net_expectancy_atr > 0.0)
   {
      selected_net_expectancy_atr = recommendation.execution_net_expectancy_atr;
   }

   if(use_deep_execution)
      risk_percent = ModelDeepDerivedRiskPercent(recommendation.deep_best_probability,
                                                 recommendation.deep_best_confidence,
                                                 recommendation.frequency_bias);
   else if(recommendation.execution_risk_percent > 0.0)
      risk_percent = recommendation.execution_risk_percent;
   else
      risk_percent = ModelDerivedRiskPercent(selected_score,
                                             selected_samples,
                                             recommendation.frequency_bias,
                                             recommendation.direction_confidence);

   if(IsModelNetExpectancyBlocked(selected_net_expectancy_atr,
                                  selected_source,
                                  reason))
      return(false);

   if(use_deep_execution && selected_stop_atr > 0.0)
      stop_atr = selected_stop_atr;
   else if(recommendation.execution_stop_atr > 0.0)
      stop_atr = recommendation.execution_stop_atr;
   else if(selected_stop_atr > 0.0)
      stop_atr = selected_stop_atr;

   if(use_deep_execution && selected_target_atr > 0.0)
      target_atr = selected_target_atr;
   else if(recommendation.execution_target_atr > 0.0)
      target_atr = recommendation.execution_target_atr;
   else if(selected_target_atr > 0.0)
      target_atr = selected_target_atr;
   else
      target_atr = stop_atr * 1.5;

   if(recommendation.execution_max_positions_per_direction > 0)
      max_positions_per_direction = recommendation.execution_max_positions_per_direction;

   if(recommendation.execution_cooldown_minutes > 0)
      cooldown_minutes = recommendation.execution_cooldown_minutes;

   risk_percent = ClampModelExecutionDouble(risk_percent,
                                            InpModelExecutionMinRiskPercent,
                                            InpModelExecutionMaxRiskPercent);
   stop_atr = ClampModelExecutionDouble(stop_atr,
                                        InpModelExecutionMinStopATR,
                                        InpModelExecutionMaxStopATR);
   target_atr = ClampModelExecutionDouble(target_atr,
                                          InpModelExecutionMinTargetATR,
                                          InpModelExecutionMaxTargetATR);

   reason = "execution_plan=" +
            (recommendation.execution_plan_found ? "model" : "derived") +
            ", source=" + selected_source +
            ", risk_percent=" + DoubleToString(risk_percent, 3) +
            ", net_expectancy_atr=" + DoubleToString(selected_net_expectancy_atr, 4) +
            ", stop_atr=" + DoubleToString(stop_atr, 3) +
            ", target_atr=" + DoubleToString(target_atr, 3) +
            ", max_positions=" + IntegerToString(max_positions_per_direction) +
            ", cooldown_min=" + IntegerToString(cooldown_minutes) +
            ", deep_probability=" + DoubleToString(recommendation.deep_best_probability, 3) +
            ", deep_confidence=" + DoubleToString(recommendation.deep_best_confidence, 3);
   return(true);
}

bool GetModelPositionManagementPlan(const TradeSignal signal,
                                    double &trail_start_atr,
                                    double &trail_distance_atr,
                                    int &hold_bars,
                                    string &reason)
{
   trail_start_atr = 0.0;
   trail_distance_atr = 0.0;
   hold_bars = 0;
   reason = "";

   if(!InpUseModelExecutionPlan)
   {
      reason = "model execution plan disabled";
      return(false);
   }

   CodexModelRecommendation recommendation;
   string symbol_object = "";
   if(!LoadModelRecommendationCore(recommendation, symbol_object, reason))
      return(false);

   string selected_source = "";
   double selected_score = 0.0;
   double selected_net_expectancy_atr = 0.0;
   int selected_samples = 0;
   double selected_stop_atr = 0.0;
   double selected_target_atr = 0.0;
   int selected_hold_bars = 0;
   double selected_trail_start_atr = 0.0;
   double selected_trail_distance_atr = 0.0;
   SelectModelDirectRuleForSignal(recommendation,
                                  signal,
                                  selected_source,
                                  selected_score,
                                  selected_net_expectancy_atr,
                                  selected_samples,
                                  selected_stop_atr,
                                  selected_target_atr,
                                  selected_hold_bars,
                                  selected_trail_start_atr,
                                  selected_trail_distance_atr);

   const bool use_deep_management =
      InpModelExecutionPreferDeepModel &&
      recommendation.deep_model_found &&
      recommendation.deep_best_action == SignalToText(signal) &&
      recommendation.deep_best_probability >= InpDeepModelMinProbability &&
      recommendation.deep_best_confidence >= InpDeepModelMinConfidence;

   if(use_deep_management)
   {
      selected_source = "deep_model";
      selected_score = recommendation.deep_best_probability;
      selected_net_expectancy_atr = recommendation.deep_best_net_expectancy_atr;
      selected_samples = recommendation.deep_best_rule_samples;
      selected_hold_bars = recommendation.deep_best_hold_bars;
      selected_trail_start_atr = recommendation.deep_best_trail_start_atr;
      selected_trail_distance_atr = recommendation.deep_best_trail_distance_atr;
      selected_stop_atr = recommendation.deep_best_stop_atr;
      selected_target_atr = recommendation.deep_best_target_atr;
   }
   else if(selected_net_expectancy_atr <= 0.0 && recommendation.execution_net_expectancy_atr > 0.0)
   {
      selected_net_expectancy_atr = recommendation.execution_net_expectancy_atr;
   }

   if(selected_trail_start_atr > 0.0)
      trail_start_atr = selected_trail_start_atr;
   else if(recommendation.execution_trail_start_atr > 0.0)
      trail_start_atr = recommendation.execution_trail_start_atr;
   else if(selected_target_atr > 0.0)
      trail_start_atr = MathMax(0.10, selected_target_atr * 0.45);

   if(selected_trail_distance_atr > 0.0)
      trail_distance_atr = selected_trail_distance_atr;
   else if(recommendation.execution_trail_distance_atr > 0.0)
      trail_distance_atr = recommendation.execution_trail_distance_atr;
   else if(selected_stop_atr > 0.0)
      trail_distance_atr = MathMax(0.08, selected_stop_atr * 0.50);

   if(selected_hold_bars > 0)
      hold_bars = selected_hold_bars;
   else if(recommendation.execution_hold_bars > 0)
      hold_bars = recommendation.execution_hold_bars;

   if(trail_start_atr <= 0.0 || trail_distance_atr <= 0.0)
   {
      reason = "model trailing plan missing usable ATR distances";
      return(false);
   }

   trail_start_atr = ClampModelExecutionDouble(trail_start_atr,
                                               InpModelExecutionMinTrailATR,
                                               InpModelExecutionMaxTrailATR);
   trail_distance_atr = ClampModelExecutionDouble(trail_distance_atr,
                                                  InpModelExecutionMinTrailATR,
                                                  InpModelExecutionMaxTrailATR);

   reason = "management_source=" + selected_source +
            ", hold_bars=" + IntegerToString(hold_bars) +
            ", trail_start_atr=" + DoubleToString(trail_start_atr, 3) +
            ", trail_distance_atr=" + DoubleToString(trail_distance_atr, 3) +
            ", score=" + DoubleToString(selected_score, 3) +
            ", net_expectancy_atr=" + DoubleToString(selected_net_expectancy_atr, 4) +
            ", samples=" + IntegerToString(selected_samples);
   return(true);
}

void SelectModelDirectRuleForSignal(const CodexModelRecommendation &recommendation,
                                    const TradeSignal signal,
                                    string &selected_source,
                                    double &selected_score,
                                    double &selected_net_expectancy_atr,
                                    int &selected_samples,
                                    double &selected_stop_atr,
                                    double &selected_target_atr,
                                    int &selected_hold_bars,
                                    double &selected_trail_start_atr,
                                    double &selected_trail_distance_atr)
{
   selected_source = "";
   selected_score = 0.0;
   selected_net_expectancy_atr = 0.0;
   selected_samples = 0;
   selected_stop_atr = 0.0;
   selected_target_atr = 0.0;
   selected_hold_bars = 0;
   selected_trail_start_atr = 0.0;
   selected_trail_distance_atr = 0.0;

   const string signal_text = SignalToText(signal);
   if(InpModelDirectUseTopRule &&
      recommendation.top_rule_found &&
      recommendation.top_direction == signal_text)
   {
      selected_source = "top_short_rule";
      selected_score = recommendation.top_score;
      selected_net_expectancy_atr = recommendation.top_net_expectancy_atr;
      selected_samples = recommendation.top_samples;
      selected_stop_atr = recommendation.top_stop_atr;
      selected_target_atr = recommendation.top_target_atr;
      selected_hold_bars = recommendation.top_hold_bars;
      selected_trail_start_atr = recommendation.top_trail_start_atr;
      selected_trail_distance_atr = recommendation.top_trail_distance_atr;
      return;
   }

   if(recommendation.aligned_rule_found &&
      recommendation.aligned_direction == signal_text)
   {
      selected_source = "aligned_short_rule";
      selected_score = recommendation.aligned_score;
      selected_net_expectancy_atr = recommendation.aligned_net_expectancy_atr;
      selected_samples = recommendation.aligned_samples;
      selected_stop_atr = recommendation.aligned_stop_atr;
      selected_target_atr = recommendation.aligned_target_atr;
      selected_hold_bars = recommendation.aligned_hold_bars;
      selected_trail_start_atr = recommendation.aligned_trail_start_atr;
      selected_trail_distance_atr = recommendation.aligned_trail_distance_atr;
      return;
   }

   if(recommendation.top_rule_found)
   {
      selected_source = "top_short_rule";
      selected_score = recommendation.top_score;
      selected_net_expectancy_atr = recommendation.top_net_expectancy_atr;
      selected_samples = recommendation.top_samples;
      selected_stop_atr = recommendation.top_stop_atr;
      selected_target_atr = recommendation.top_target_atr;
      selected_hold_bars = recommendation.top_hold_bars;
      selected_trail_start_atr = recommendation.top_trail_start_atr;
      selected_trail_distance_atr = recommendation.top_trail_distance_atr;
   }
}

double ModelDerivedRiskPercent(const double score,
                               const int samples,
                               string frequency_bias,
                               const double confidence)
{
   StringToUpper(frequency_bias);
   double risk = 0.20;
   if(frequency_bias == "NORMAL")
      risk = 0.30;
   else if(frequency_bias == "HIGH")
      risk = 0.45;

   if(score > 1.50)
      risk += MathMin((score - 1.50) * 0.08, 0.18);
   if(samples >= 150)
      risk += 0.05;
   if(confidence >= 0.60)
      risk += 0.05;

   return(risk);
}

double ModelDeepDerivedRiskPercent(const double probability,
                                   const double confidence,
                                   string frequency_bias)
{
   StringToUpper(frequency_bias);
   double risk = 0.15;
   if(frequency_bias == "NORMAL")
      risk = 0.25;
   else if(frequency_bias == "HIGH")
      risk = 0.35;

   if(probability > InpDeepModelMinProbability)
      risk += MathMin((probability - InpDeepModelMinProbability) * 0.80, 0.20);
   if(confidence > InpDeepModelMinConfidence)
      risk += MathMin(confidence * 0.20, 0.10);

   return(risk);
}

double ClampModelExecutionDouble(const double value,
                                 const double minimum,
                                 const double maximum)
{
   double result = value;
   if(maximum > minimum)
   {
      if(result < minimum)
         result = minimum;
      if(result > maximum)
         result = maximum;
   }
   return(result);
}

int CountModelStrategyPositions(const TradeSignal signal)
{
   int count = 0;
   const long expected_type = signal == SIGNAL_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(magic != InpMagicNumber)
         continue;

      if(PositionGetInteger(POSITION_TYPE) == expected_type)
         count++;
   }

   return(count);
}

bool LoadModelRecommendation(const TradeSignal signal,
                             CodexModelRecommendation &recommendation,
                             string &reason)
{
   string symbol_object = "";
   if(!LoadModelRecommendationCore(recommendation, symbol_object, reason))
      return(false);

   string top_by_direction_object = "";
   string direction_rule_object = "";
   if(ExtractModelJsonObject(symbol_object, "top_by_direction", top_by_direction_object) &&
      ExtractModelJsonObject(top_by_direction_object, SignalToText(signal), direction_rule_object))
   {
      recommendation.signal_rule_found = true;
      ReadModelRuleMetrics(direction_rule_object,
                           recommendation.signal_score,
                           recommendation.signal_samples,
                           recommendation.signal_stop_atr,
                           recommendation.signal_target_atr,
                           recommendation.signal_hold_bars,
                           recommendation.signal_trail_start_atr,
                           recommendation.signal_trail_distance_atr,
                           recommendation.signal_net_expectancy_atr);
   }

   recommendation.available = true;
   return(true);
}

bool LoadModelRecommendationCore(CodexModelRecommendation &recommendation,
                                 string &symbol_object,
                                 string &reason)
{
   ResetModelRecommendation(recommendation);
   symbol_object = "";

   string json = "";
   if(!ReadModelRecommendationFile(json))
   {
      reason = "model recommendation file missing or empty: " + InpModelRecommendationFile;
      return(false);
   }

   double generated_at_value = 0.0;
   if(TryReadModelJsonNumber(json, "generated_at", generated_at_value))
   {
      recommendation.generated_at = (datetime)generated_at_value;
      const datetime now_utc = TimeGMT();
      if(InpModelMaxAgeSeconds > 0 &&
         recommendation.generated_at > 0 &&
         now_utc - recommendation.generated_at > InpModelMaxAgeSeconds)
      {
         reason = "model recommendation is stale: generated_at=" +
                  TimeToString(recommendation.generated_at, TIME_DATE | TIME_SECONDS);
         return(false);
      }
   }

   string symbols_object = "";
   if(!ExtractModelJsonObject(json, "symbols", symbols_object))
   {
      reason = "model recommendations missing symbols object";
      return(false);
   }

   if(!ExtractModelJsonObject(symbols_object, ConfiguredSymbol(), symbol_object) &&
      !ExtractModelJsonObject(symbols_object, _Symbol, symbol_object))
   {
      reason = "model recommendations missing symbol " + ConfiguredSymbol();
      return(false);
   }

   string direction_bias = "";
   if(TryReadModelJsonString(symbol_object, "direction_bias", direction_bias))
      recommendation.direction_bias = direction_bias;

   string frequency_bias = "";
   if(TryReadModelJsonString(symbol_object, "frequency_bias", frequency_bias))
      recommendation.frequency_bias = frequency_bias;
   if(recommendation.frequency_bias == "")
      recommendation.frequency_bias = "LOW";

   string daily_object = "";
   if(ExtractModelJsonObject(symbol_object, "daily", daily_object))
      TryReadModelJsonNumber(daily_object, "direction_confidence", recommendation.direction_confidence);

   string top_rule_object = "";
   if(ExtractModelJsonObject(symbol_object, "top_short_rule", top_rule_object))
   {
      recommendation.top_rule_found = true;
      TryReadModelJsonString(top_rule_object, "direction", recommendation.top_direction);
      ReadModelRuleMetrics(top_rule_object,
                           recommendation.top_score,
                           recommendation.top_samples,
                           recommendation.top_stop_atr,
                           recommendation.top_target_atr,
                           recommendation.top_hold_bars,
                           recommendation.top_trail_start_atr,
                           recommendation.top_trail_distance_atr,
                           recommendation.top_net_expectancy_atr);
   }

   string aligned_rule_object = "";
   if(ExtractModelJsonObject(symbol_object, "aligned_short_rule", aligned_rule_object))
   {
      recommendation.aligned_rule_found = true;
      TryReadModelJsonString(aligned_rule_object, "direction", recommendation.aligned_direction);
      ReadModelRuleMetrics(aligned_rule_object,
                           recommendation.aligned_score,
                           recommendation.aligned_samples,
                           recommendation.aligned_stop_atr,
                           recommendation.aligned_target_atr,
                           recommendation.aligned_hold_bars,
                           recommendation.aligned_trail_start_atr,
                           recommendation.aligned_trail_distance_atr,
                           recommendation.aligned_net_expectancy_atr);
   }

   string execution_plan_object = "";
   if(ExtractModelJsonObject(symbol_object, "execution_plan", execution_plan_object))
   {
      recommendation.execution_plan_found = true;
      TryReadModelJsonNumber(execution_plan_object, "net_expectancy_atr", recommendation.execution_net_expectancy_atr);
      TryReadModelJsonNumber(execution_plan_object, "estimated_cost_atr", recommendation.execution_estimated_cost_atr);
      TryReadModelJsonNumber(execution_plan_object, "risk_percent", recommendation.execution_risk_percent);
      TryReadModelJsonNumber(execution_plan_object, "stop_atr", recommendation.execution_stop_atr);
      TryReadModelJsonNumber(execution_plan_object, "target_atr", recommendation.execution_target_atr);
      TryReadModelJsonNumber(execution_plan_object, "trail_start_atr", recommendation.execution_trail_start_atr);
      TryReadModelJsonNumber(execution_plan_object, "trail_distance_atr", recommendation.execution_trail_distance_atr);

      double hold_value = 0.0;
      if(TryReadModelJsonNumber(execution_plan_object, "hold_bars", hold_value))
         recommendation.execution_hold_bars = (int)hold_value;

      double cooldown_value = 0.0;
      if(TryReadModelJsonNumber(execution_plan_object, "cooldown_minutes", cooldown_value))
         recommendation.execution_cooldown_minutes = (int)cooldown_value;

      double max_positions_value = 0.0;
      if(TryReadModelJsonNumber(execution_plan_object, "max_positions_per_direction", max_positions_value))
         recommendation.execution_max_positions_per_direction = (int)max_positions_value;
   }

   string deep_model_object = "";
   if(ExtractModelJsonObject(symbol_object, "deep_model", deep_model_object))
   {
      recommendation.deep_model_found = true;
      TryReadModelJsonString(deep_model_object, "best_action", recommendation.deep_best_action);
      TryReadModelJsonString(deep_model_object, "best_direction", recommendation.deep_best_direction);
      TryReadModelJsonString(deep_model_object, "best_source_model", recommendation.deep_best_source_model);
      TryReadModelJsonString(deep_model_object, "best_run_id", recommendation.deep_best_run_id);
      TryReadModelJsonString(deep_model_object, "best_candle_time", recommendation.deep_best_candle_time);
      StringToUpper(recommendation.deep_best_action);
      StringToUpper(recommendation.deep_best_direction);
      StringToUpper(recommendation.deep_best_source_model);
      TryReadModelJsonNumber(deep_model_object, "best_probability", recommendation.deep_best_probability);
      TryReadModelJsonNumber(deep_model_object, "best_confidence", recommendation.deep_best_confidence);
      TryReadModelJsonNumber(deep_model_object, "best_net_expectancy_atr", recommendation.deep_best_net_expectancy_atr);
      TryReadModelJsonNumber(deep_model_object, "best_estimated_cost_atr", recommendation.deep_best_estimated_cost_atr);
      TryReadModelJsonNumber(deep_model_object, "best_net_win_rate", recommendation.deep_best_net_win_rate);
      TryReadModelJsonNumber(deep_model_object, "best_suggested_stop_atr", recommendation.deep_best_stop_atr);
      TryReadModelJsonNumber(deep_model_object, "best_suggested_target_atr", recommendation.deep_best_target_atr);
      TryReadModelJsonNumber(deep_model_object, "best_suggested_trail_start_atr", recommendation.deep_best_trail_start_atr);
      TryReadModelJsonNumber(deep_model_object, "best_suggested_trail_distance_atr", recommendation.deep_best_trail_distance_atr);
      TryReadModelJsonNumber(deep_model_object, "best_rule_score", recommendation.deep_best_rule_score);

      double deep_hold_bars = 0.0;
      if(TryReadModelJsonNumber(deep_model_object, "best_suggested_hold_bars", deep_hold_bars))
         recommendation.deep_best_hold_bars = (int)deep_hold_bars;

      double deep_rule_samples = 0.0;
      if(TryReadModelJsonNumber(deep_model_object, "best_rule_samples", deep_rule_samples))
         recommendation.deep_best_rule_samples = (int)deep_rule_samples;
   }

   recommendation.available = true;
   return(true);
}

void ResetModelRecommendation(CodexModelRecommendation &recommendation)
{
   recommendation.available = false;
   recommendation.generated_at = 0;
   recommendation.direction_bias = "";
   recommendation.frequency_bias = "";
   recommendation.direction_confidence = 0.0;
   recommendation.signal_rule_found = false;
   recommendation.signal_score = 0.0;
   recommendation.signal_net_expectancy_atr = 0.0;
   recommendation.signal_samples = 0;
   recommendation.signal_stop_atr = 0.0;
   recommendation.signal_target_atr = 0.0;
   recommendation.signal_hold_bars = 0;
   recommendation.signal_trail_start_atr = 0.0;
   recommendation.signal_trail_distance_atr = 0.0;
   recommendation.top_rule_found = false;
   recommendation.top_direction = "";
   recommendation.top_score = 0.0;
   recommendation.top_net_expectancy_atr = 0.0;
   recommendation.top_samples = 0;
   recommendation.top_stop_atr = 0.0;
   recommendation.top_target_atr = 0.0;
   recommendation.top_hold_bars = 0;
   recommendation.top_trail_start_atr = 0.0;
   recommendation.top_trail_distance_atr = 0.0;
   recommendation.aligned_rule_found = false;
   recommendation.aligned_direction = "";
   recommendation.aligned_score = 0.0;
   recommendation.aligned_net_expectancy_atr = 0.0;
   recommendation.aligned_samples = 0;
   recommendation.aligned_stop_atr = 0.0;
   recommendation.aligned_target_atr = 0.0;
   recommendation.aligned_hold_bars = 0;
   recommendation.aligned_trail_start_atr = 0.0;
   recommendation.aligned_trail_distance_atr = 0.0;
   recommendation.execution_plan_found = false;
   recommendation.execution_net_expectancy_atr = 0.0;
   recommendation.execution_estimated_cost_atr = 0.0;
   recommendation.execution_risk_percent = 0.0;
   recommendation.execution_stop_atr = 0.0;
   recommendation.execution_target_atr = 0.0;
   recommendation.execution_hold_bars = 0;
   recommendation.execution_trail_start_atr = 0.0;
   recommendation.execution_trail_distance_atr = 0.0;
   recommendation.execution_cooldown_minutes = 0;
   recommendation.execution_max_positions_per_direction = 0;
   recommendation.deep_model_found = false;
   recommendation.deep_best_action = "";
   recommendation.deep_best_direction = "";
   recommendation.deep_best_source_model = "";
   recommendation.deep_best_run_id = "";
   recommendation.deep_best_candle_time = "";
   recommendation.deep_best_probability = 0.0;
   recommendation.deep_best_confidence = 0.0;
   recommendation.deep_best_net_expectancy_atr = 0.0;
   recommendation.deep_best_estimated_cost_atr = 0.0;
   recommendation.deep_best_net_win_rate = 0.0;
   recommendation.deep_best_stop_atr = 0.0;
   recommendation.deep_best_target_atr = 0.0;
   recommendation.deep_best_hold_bars = 0;
   recommendation.deep_best_trail_start_atr = 0.0;
   recommendation.deep_best_trail_distance_atr = 0.0;
   recommendation.deep_best_rule_score = 0.0;
   recommendation.deep_best_rule_samples = 0;
}

void ReadModelRuleMetrics(const string rule_object,
                          double &score,
                          int &samples,
                          double &stop_atr,
                          double &target_atr,
                          int &hold_bars,
                          double &trail_start_atr,
                          double &trail_distance_atr,
                          double &net_expectancy_atr)
{
   score = 0.0;
   samples = 0;
   stop_atr = 0.0;
   target_atr = 0.0;
   hold_bars = 0;
   trail_start_atr = 0.0;
   trail_distance_atr = 0.0;
   net_expectancy_atr = 0.0;

   TryReadModelJsonNumber(rule_object, "score", score);
   TryReadModelJsonNumber(rule_object, "net_expectancy_atr", net_expectancy_atr);

   double samples_value = 0.0;
   if(TryReadModelJsonNumber(rule_object, "samples", samples_value))
      samples = (int)samples_value;

   TryReadModelJsonNumber(rule_object, "suggested_stop_atr", stop_atr);
   TryReadModelJsonNumber(rule_object, "suggested_target_atr", target_atr);
   TryReadModelJsonNumber(rule_object, "suggested_trail_start_atr", trail_start_atr);
   TryReadModelJsonNumber(rule_object, "suggested_trail_distance_atr", trail_distance_atr);

   double hold_value = 0.0;
   if(TryReadModelJsonNumber(rule_object, "suggested_hold_bars", hold_value))
      hold_bars = (int)hold_value;
}

TradeSignal ModelSignalFromText(string direction)
{
   StringToUpper(direction);
   if(direction == "BUY")
      return(SIGNAL_BUY);
   if(direction == "SELL")
      return(SIGNAL_SELL);

   return(SIGNAL_NONE);
}

bool IsModelFrequencyThrottled(const TradeSignal signal,
                               const string frequency_bias,
                               string &reason)
{
   int cooldown_minutes = 0;
   string normalized = frequency_bias;
   StringToUpper(normalized);

   if(normalized == "LOW")
      cooldown_minutes = InpModelLowFrequencyCooldownMinutes;
   else if(normalized == "NORMAL")
      cooldown_minutes = InpModelNormalFrequencyCooldownMinutes;
   else if(normalized == "HIGH")
      cooldown_minutes = InpModelHighFrequencyCooldownMinutes;

   if(cooldown_minutes <= 0)
      return(false);

   string key = ModelLastEntryKey(signal);
   if(!GlobalVariableCheck(key))
      return(false);

   datetime last_entry = (datetime)GlobalVariableGet(key);
   if(last_entry <= 0)
      return(false);

   int elapsed_seconds = (int)(TimeCurrent() - last_entry);
   int cooldown_seconds = cooldown_minutes * 60;
   if(elapsed_seconds >= cooldown_seconds)
      return(false);

   reason = "model frequency throttle: freq=" + normalized +
            ", elapsed_min=" + IntegerToString(elapsed_seconds / 60) +
            ", cooldown_min=" + IntegerToString(cooldown_minutes);
   return(true);
}

string ModelLastEntryKey(const TradeSignal signal)
{
   return("CodexModelLastEntry." +
          IntegerToString((long)InpMagicNumber) +
          "." + ConfiguredSymbol() +
          "." + SignalToText(signal));
}

bool ReadModelRecommendationFile(string &json)
{
   json = "";
   string symbol_file = ModelSymbolRecommendationFile();
   if(symbol_file != "" && ReadModelRecommendationFileFromPath(symbol_file, json))
      return(true);

   if(ReadModelRecommendationFileFromPath(InpModelRecommendationFile, json))
      return(true);

   if(TimeCurrent() - codex_model_last_missing_warning > 300)
   {
      LogVerbose("Model recommendation file is not available: " +
                 symbol_file +
                 " or " +
                 InpModelRecommendationFile +
                 ". Trading will follow InpAllowTradeWhenModelMissing.");
      codex_model_last_missing_warning = TimeCurrent();
   }
   return(false);
}

string ModelSymbolRecommendationFile()
{
   string configured_file = InpModelRecommendationFile;
   string separator = "\\";
   int last_separator = -1;
   for(int i = 0; i < StringLen(configured_file); ++i)
   {
      string ch = StringSubstr(configured_file, i, 1);
      if(ch == "\\" || ch == "/")
      {
         last_separator = i;
         separator = ch;
      }
   }

   string folder = "codex-edge-model";
   if(last_separator >= 0)
      folder = StringSubstr(configured_file, 0, last_separator);

   string symbol = ConfiguredSymbol();
   if(symbol == "")
      symbol = _Symbol;
   StringToUpper(symbol);
   return(folder + separator + "symbols" + separator + symbol + ".json");
}

bool ReadModelRecommendationFileFromPath(const string file_name, string &json)
{
   json = "";
   ResetLastError();
   int handle = FileOpen(file_name,
                         FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ);
   if(handle == INVALID_HANDLE)
      return(false);

   while(!FileIsEnding(handle))
      json += FileReadString(handle);
   FileClose(handle);

   return(StringLen(json) > 0);
}

bool ExtractModelJsonObject(const string json, const string key, string &object_text)
{
   object_text = "";
   int key_pos = FindModelJsonKey(json, key);
   if(key_pos < 0)
      return(false);

   int colon_pos = StringFind(json, ":", key_pos + StringLen(key) + 2);
   if(colon_pos < 0)
      return(false);

   int start_pos = -1;
   for(int i = colon_pos + 1; i < StringLen(json); i++)
   {
      string ch = StringSubstr(json, i, 1);
      if(IsModelJsonWhitespace(ch))
         continue;
      if(ch != "{")
         return(false);
      start_pos = i;
      break;
   }

   if(start_pos < 0)
      return(false);

   int depth = 0;
   bool in_string = false;
   bool escaped = false;
   for(int i = start_pos; i < StringLen(json); i++)
   {
      string ch = StringSubstr(json, i, 1);
      if(in_string)
      {
         if(escaped)
         {
            escaped = false;
            continue;
         }
         if(ch == "\\")
         {
            escaped = true;
            continue;
         }
         if(ch == "\"")
            in_string = false;
         continue;
      }

      if(ch == "\"")
      {
         in_string = true;
         continue;
      }
      if(ch == "{")
         depth++;
      else if(ch == "}")
      {
         depth--;
         if(depth == 0)
         {
            object_text = StringSubstr(json, start_pos, i - start_pos + 1);
            return(true);
         }
      }
   }

   return(false);
}

bool TryReadModelJsonNumber(const string json, const string key, double &value)
{
   value = 0.0;
   int key_pos = FindModelJsonKey(json, key);
   if(key_pos < 0)
      return(false);

   int colon_pos = StringFind(json, ":", key_pos + StringLen(key) + 2);
   if(colon_pos < 0)
      return(false);

   string token = "";
   bool in_string = false;
   for(int i = colon_pos + 1; i < StringLen(json); i++)
   {
      string ch = StringSubstr(json, i, 1);
      if(token == "" && IsModelJsonWhitespace(ch))
         continue;
      if(token == "" && ch == "\"")
      {
         in_string = true;
         continue;
      }
      if((!in_string && (ch == "," || ch == "}" || ch == "]")) ||
         (in_string && ch == "\""))
         break;
      if(IsModelJsonWhitespace(ch))
         continue;
      token += ch;
   }

   if(token == "")
      return(false);

   value = StringToDouble(token);
   return(true);
}

bool TryReadModelJsonString(const string json, const string key, string &value)
{
   value = "";
   int key_pos = FindModelJsonKey(json, key);
   if(key_pos < 0)
      return(false);

   int colon_pos = StringFind(json, ":", key_pos + StringLen(key) + 2);
   if(colon_pos < 0)
      return(false);

   int start_pos = -1;
   for(int i = colon_pos + 1; i < StringLen(json); i++)
   {
      string ch = StringSubstr(json, i, 1);
      if(IsModelJsonWhitespace(ch))
         continue;
      if(ch != "\"")
         return(false);
      start_pos = i + 1;
      break;
   }

   if(start_pos < 0)
      return(false);

   int end_pos = StringFind(json, "\"", start_pos);
   if(end_pos < 0)
      return(false);

   value = StringSubstr(json, start_pos, end_pos - start_pos);
   return(value != "");
}

int FindModelJsonKey(const string json, const string key)
{
   return(StringFind(json, "\"" + key + "\""));
}

bool IsModelJsonWhitespace(const string ch)
{
   return(ch == " " || ch == "\r" || ch == "\n" || ch == "\t");
}

# frozen_string_literal: true

# Collection of constants.
module Constants
  BathToShowerRatio = 0.078843
  BathDurationMean = 5.65
  BathDurationStd = 2.09
  BathFlowRateMean = 4.4
  BathFlowRateStd = 1.17
  HotWaterDishwasherFlowRateMean = 1.39
  HotWaterDishwasherFlowRateStd = 0.2
  HotWaterDishwasherMinutesBetweenEventGap = 10
  HotWaterClothesWasherFlowRateMean = 2.2
  HotWaterClothesWasherFlowRateStd = 0.62
  HotWaterClothesWasherMinutesBetweenEventGap = 4
  HotWaterClothesWasherLoadSizeProbability = '0.682926829, 0.227642276, 0.056910569, 0.032520325'
  OccupancyTypesProbabilities = '0.381, 0.297, 0.165, 0.157'
  ShowerMinutesBetweenEventGap = 30
  ShowerFlowRateMean = 2.25
  ShowerFlowRateStd = 0.68
  SinkDurationProbability = '0.901242, 0.076572, 0.01722, 0.003798, 0.000944, 0.000154, 4.6e-05, 2.2e-05, 2.0e-06'
  SinkEventsPerClusterProbs = '0.62458, 0.18693, 0.08011, 0.0433, 0.02178, 0.01504, 0.0083, 0.00467, 0.0057, 0.00285, 0.00181, 0.00233, 0.0013, 0.00104, 0.00026'
  SinkHourlyOnsetProb = '0.007, 0.018, 0.042, 0.062, 0.066, 0.062, 0.054, 0.05, 0.049, 0.045, 0.041, 0.043, 0.048, 0.065, 0.075, 0.069, 0.057, 0.048, 0.04, 0.027, 0.014, 0.007, 0.005, 0.005'
  SinkAvgSinkClustersPerHH = 6657
  SinkMinutesBetweenEventGap = 2
  SinkFlowRateMean = 1.14
  SinkFlowRateStd = 0.61
end

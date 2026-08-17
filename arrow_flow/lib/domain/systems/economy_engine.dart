import '../../core/config/app_config.dart';

/// Pure Dart Economy Engine for Sparks soft currency calculations.
class EconomyEngine {
  final EconomyConfig config;
  final int secondWindCost;

  const EconomyEngine({
    required this.config,
    required this.secondWindCost,
  });

  /// Calculates Sparks earned upon completing a level.
  int calculateLevelCompletionEarnings({
    required int stars,
    required bool flowStateReached,
    bool isDailyChallenge = false,
  }) {
    if (stars <= 0) return 0;
    int total = stars * config.sparksPerStar;
    if (flowStateReached) {
      total += config.sparksPerFlowState;
    }
    if (isDailyChallenge) {
      total += config.sparksPerDailyChallenge;
    }
    return total;
  }

  /// Sparks earned from watching a rewarded ad bonus.
  int get rewardedAdBonus => config.rewardedAdSparksBonus;

  /// Cost to buy a hint with Sparks.
  int get hintCost => config.hintCostSparks;

  /// Cost for second wind revive.
  int get secondWindCostSparks => secondWindCost;

  /// Checks whether player can afford a specific cost.
  bool canAfford(int currentBalance, int cost) {
    return currentBalance >= cost;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/core/config/app_config.dart';
import 'package:arrow_flow/domain/systems/economy_engine.dart';

void main() {
  group('EconomyEngine', () {
    const config = EconomyConfig(
      sparksPerStar: 5,
      sparksPerFlowState: 15,
      sparksPerDailyChallenge: 30,
      rewardedAdSparksBonus: 20,
      hintCostSparks: 15,
    );
    const engine = EconomyEngine(config: config, secondWindCost: 50);

    test('calculateLevelCompletionEarnings calculates correctly', () {
      // 3 stars + flow state
      final e1 = engine.calculateLevelCompletionEarnings(
        stars: 3,
        flowStateReached: true,
      );
      expect(e1, 3 * 5 + 15); // 30

      // 1 star + no flow state
      final e2 = engine.calculateLevelCompletionEarnings(
        stars: 1,
        flowStateReached: false,
      );
      expect(e2, 5);

      // Daily challenge bonus
      final e3 = engine.calculateLevelCompletionEarnings(
        stars: 2,
        flowStateReached: false,
        isDailyChallenge: true,
      );
      expect(e3, 2 * 5 + 30); // 40
    });

    test('canAfford checks balance accurately', () {
      expect(engine.canAfford(50, 50), isTrue);
      expect(engine.canAfford(49, 50), isFalse);
    });
  });
}

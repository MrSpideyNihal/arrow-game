import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/domain/systems/combo_engine.dart';

void main() {
  group('ComboEngine', () {
    const engine = ComboEngine(comboWindowMs: 1400, thresholds: [3, 6, 10]);

    test('initial state has 0 combo and tier 0', () {
      final state = ComboState.initial();
      expect(state.comboCount, 0);
      expect(state.currentTier, 0);
      expect(state.flowStateReached, isFalse);
    });

    test('hits within window increase combo count and tier', () {
      var state = ComboState.initial();
      int time = 1000;

      // Hit 1..3
      state = engine.recordHit(state, time);
      expect(state.comboCount, 1);
      expect(state.currentTier, 0);

      time += 500;
      state = engine.recordHit(state, time);
      expect(state.comboCount, 2);
      expect(state.currentTier, 0);

      time += 500;
      state = engine.recordHit(state, time);
      expect(state.comboCount, 3);
      expect(state.currentTier, 1); // x2 tier at 3 hits
    });

    test('reaching 10 hits triggers FLOW STATE', () {
      var state = ComboState.initial();
      int time = 1000;

      for (int i = 1; i <= 10; i++) {
        time += 200;
        state = engine.recordHit(state, time);
      }

      expect(state.comboCount, 10);
      expect(state.currentTier, 3); // FLOW STATE
      expect(state.flowStateReached, isTrue);
    });

    test('hit outside combo window resets combo count to 1', () {
      var state = ComboState.initial();
      state = engine.recordHit(state, 1000);
      state = engine.recordHit(state, 1500); // 2 hits

      // Next hit after 2000ms (diff 2000 > 1400)
      state = engine.recordHit(state, 3500);
      expect(state.comboCount, 1);
      expect(state.currentTier, 0);
    });

    test('recordMiss resets combo multiplier but retains flowStateReached', () {
      var state = ComboState.initial();
      int time = 1000;

      for (int i = 1; i <= 10; i++) {
        time += 200;
        state = engine.recordHit(state, time);
      }
      expect(state.flowStateReached, isTrue);

      final missedState = engine.recordMiss(state);
      expect(missedState.comboCount, 0);
      expect(missedState.currentTier, 0);
      expect(missedState.flowStateReached, isTrue);
    });

    test('checkWindowExpiration clears active combo if window exceeded', () {
      var state = ComboState.initial();
      state = engine.recordHit(state, 1000);

      final stateBefore = engine.checkWindowExpiration(state, 2000); // 1000ms diff <= 1400ms
      expect(stateBefore.comboCount, 1);

      final stateAfter = engine.checkWindowExpiration(state, 2500); // 1500ms diff > 1400ms
      expect(stateAfter.comboCount, 0);
    });
  });
}

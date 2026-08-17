/// State of the Momentum Combo system during a gameplay session.
class ComboState {
  final int comboCount;
  final int currentTier; // 0 = x1, 1 = x2, 2 = x3, 3 = FLOW STATE
  final double tierProgress; // 0.0 to 1.0 within current tier
  final int lastHitTimestampMs;
  final bool flowStateReached;

  const ComboState({
    required this.comboCount,
    required this.currentTier,
    required this.tierProgress,
    required this.lastHitTimestampMs,
    required this.flowStateReached,
  });

  factory ComboState.initial() {
    return const ComboState(
      comboCount: 0,
      currentTier: 0,
      tierProgress: 0.0,
      lastHitTimestampMs: 0,
      flowStateReached: false,
    );
  }

  ComboState copyWith({
    int? comboCount,
    int? currentTier,
    double? tierProgress,
    int? lastHitTimestampMs,
    bool? flowStateReached,
  }) {
    return ComboState(
      comboCount: comboCount ?? this.comboCount,
      currentTier: currentTier ?? this.currentTier,
      tierProgress: tierProgress ?? this.tierProgress,
      lastHitTimestampMs: lastHitTimestampMs ?? this.lastHitTimestampMs,
      flowStateReached: flowStateReached ?? this.flowStateReached,
    );
  }
}

/// Pure Dart Momentum Combo Engine.
///
/// Rules:
/// - Every arrow removed within `comboWindowMs` extends the combo.
/// - Combo Tiers:
///     Tier 0 (x1): 0..2 consecutive hits
///     Tier 1 (x2): 3..5 consecutive hits (threshold 3)
///     Tier 2 (x3): 6..9 consecutive hits (threshold 6)
///     Tier 3 (FLOW STATE): 10+ consecutive hits (threshold 10)
/// - A miss resets combo count to 0 and tier to 0, but retains `flowStateReached`.
class ComboEngine {
  final int comboWindowMs;
  final List<int> thresholds; // default e.g. [3, 6, 10]

  const ComboEngine({
    this.comboWindowMs = 1400,
    this.thresholds = const [3, 6, 10],
  });

  /// Evaluates a hit (valid arrow removal) at [timestampMs].
  ComboState recordHit(ComboState state, int timestampMs) {
    bool isWindowValid = state.comboCount == 0 ||
        (timestampMs - state.lastHitTimestampMs <= comboWindowMs);

    final newCount = isWindowValid ? state.comboCount + 1 : 1;
    final newTier = _calculateTier(newCount);
    final progress = _calculateTierProgress(newCount, newTier);
    final reachedFlow = state.flowStateReached || (newTier == 3);

    return ComboState(
      comboCount: newCount,
      currentTier: newTier,
      tierProgress: progress,
      lastHitTimestampMs: timestampMs,
      flowStateReached: reachedFlow,
    );
  }

  /// Evaluates a miss (invalid tap or timeout). Resets multiplier, preserves flowStateReached.
  ComboState recordMiss(ComboState state) {
    return ComboState(
      comboCount: 0,
      currentTier: 0,
      tierProgress: 0.0,
      lastHitTimestampMs: 0,
      flowStateReached: state.flowStateReached,
    );
  }

  /// Checks whether the combo window has expired at [currentTimestampMs].
  ComboState checkWindowExpiration(ComboState state, int currentTimestampMs) {
    if (state.comboCount > 0 &&
        (currentTimestampMs - state.lastHitTimestampMs > comboWindowMs)) {
      return recordMiss(state);
    }
    return state;
  }

  int _calculateTier(int count) {
    if (thresholds.length >= 3) {
      if (count >= thresholds[2]) return 3; // FLOW STATE
      if (count >= thresholds[1]) return 2; // x3
      if (count >= thresholds[0]) return 1; // x2
    }
    return 0; // x1
  }

  double _calculateTierProgress(int count, int tier) {
    if (thresholds.length < 3) return 0.0;
    final t1 = thresholds[0]; // 3
    final t2 = thresholds[1]; // 6
    final t3 = thresholds[2]; // 10

    switch (tier) {
      case 0:
        return (count / t1).clamp(0.0, 1.0);
      case 1:
        return ((count - t1) / (t2 - t1)).clamp(0.0, 1.0);
      case 2:
        return ((count - t2) / (t3 - t2)).clamp(0.0, 1.0);
      case 3:
        return 1.0;
      default:
        return 0.0;
    }
  }
}

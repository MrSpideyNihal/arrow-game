/// Pure Dart Star Rating Calculator.
///
/// Rules:
/// - 1 star = level cleared
/// - 2 stars = level cleared with <= 1 mistake
/// - 3 stars = level cleared with 0 mistakes AND at least one FLOW STATE reached
class StarRatingCalculator {
  StarRatingCalculator._();

  static int calculateStars({
    required bool isCleared,
    required int mistakes,
    required bool flowStateReached,
  }) {
    if (!isCleared) return 0;
    if (mistakes == 0 && flowStateReached) return 3;
    if (mistakes <= 1) return 2;
    return 1;
  }
}

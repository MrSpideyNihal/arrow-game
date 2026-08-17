import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/domain/systems/star_rating.dart';

void main() {
  group('StarRatingCalculator', () {
    test('not cleared yields 0 stars', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCleared: false,
          mistakes: 0,
          flowStateReached: true,
        ),
        0,
      );
    });

    test('cleared with 0 mistakes and flow state yields 3 stars', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCleared: true,
          mistakes: 0,
          flowStateReached: true,
        ),
        3,
      );
    });

    test('cleared with 0 mistakes without flow state yields 2 stars', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCleared: true,
          mistakes: 0,
          flowStateReached: false,
        ),
        2,
      );
    });

    test('cleared with 1 mistake yields 2 stars', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCleared: true,
          mistakes: 1,
          flowStateReached: true,
        ),
        2,
      );
    });

    test('cleared with 2 or more mistakes yields 1 star', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCleared: true,
          mistakes: 2,
          flowStateReached: true,
        ),
        1,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/domain/engine/level_generator.dart';
import 'package:arrow_flow/domain/engine/arrow_solver.dart';
import 'package:arrow_flow/domain/engine/level_validator.dart';

void main() {
  group('LevelGenerator.generate', () {
    test('generated level is always solvable', () {
      const curveSeed = 20260809;
      for (int i = 1; i <= 3; i++) {
        final level = LevelGenerator.generate(i, curveSeed);
        expect(
          ArrowSolver.isSolvable(level),
          isTrue,
          reason: 'Level $i (${level.arrowCount} arrows) must be solvable',
        );
      }
    });

    test('generated level passes validation', () {
      const curveSeed = 20260809;
      for (int i = 1; i <= 5; i++) {
        final level = LevelGenerator.generate(i, curveSeed);
        final errors = LevelValidator.validate(level);
        expect(errors, isEmpty,
            reason: 'Level $i validation errors: $errors');
      }
    });

    test('deterministic: same inputs produce same level', () {
      final level1 = LevelGenerator.generate(42, 12345);
      final level2 = LevelGenerator.generate(42, 12345);
      expect(level1.arrows.length, level2.arrows.length);
      for (int i = 0; i < level1.arrows.length; i++) {
        expect(level1.arrows[i].cells, level2.arrows[i].cells);
        expect(level1.arrows[i].direction, level2.arrows[i].direction);
      }
    });

    test('level has correct ID', () {
      final level = LevelGenerator.generate(42, 20260809);
      expect(level.id, 42);
    });
  });

  group('LevelGenerator.generateBatch', () {
    test('batch generates correct count', () {
      final levels = LevelGenerator.generateBatch(1, 5, 20260809);
      expect(levels.length, 5);
    });

    test('batch levels have sequential IDs', () {
      final levels = LevelGenerator.generateBatch(1, 5, 20260809);
      for (int i = 0; i < levels.length; i++) {
        expect(levels[i].id, i + 1);
      }
    });
  });
}

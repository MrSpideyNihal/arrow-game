import '../../data/models/level_model.dart';

/// Validates a level for schema correctness, grid bounds, and data integrity.
/// Pure Dart, no Flutter imports.
class LevelValidator {
  /// Validates a level and returns a list of error messages.
  /// An empty list means the level is valid.
  static List<String> validate(Level level) {
    final errors = <String>[];

    // Grid dimensions must be positive.
    if (level.gridWidth <= 0) {
      errors.add('Grid width must be positive, got ${level.gridWidth}');
    }
    if (level.gridHeight <= 0) {
      errors.add('Grid height must be positive, got ${level.gridHeight}');
    }

    // Must have at least one arrow.
    if (level.arrows.isEmpty) {
      errors.add('Level must have at least one arrow');
    }

    // Check for duplicate arrow IDs.
    final ids = level.arrows.map((a) => a.id).toSet();
    if (ids.length != level.arrows.length) {
      errors.add('Duplicate arrow IDs found');
    }

    // Validate each arrow.
    for (final arrow in level.arrows) {
      // Arrow must have at least 2 cells (head + at least one body cell).
      if (arrow.cells.length < 2) {
        errors.add('Arrow ${arrow.id} must have at least 2 cells');
      }

      // All cells must be within grid bounds.
      for (final (x, y) in arrow.cells) {
        if (x < 0 || x >= level.gridWidth || y < 0 || y >= level.gridHeight) {
          errors.add(
            'Arrow ${arrow.id} has cell ($x, $y) outside '
            '${level.gridWidth}x${level.gridHeight} grid',
          );
        }
      }
    }

    return errors;
  }

  /// Returns true if the level is valid (no errors).
  static bool isValid(Level level) => validate(level).isEmpty;

  /// Validates a level JSON map before deserializing.
  /// Returns errors about missing or wrongly-typed fields.
  static List<String> validateJson(Map<String, dynamic> json) {
    final errors = <String>[];

    if (json['id'] is! int) {
      errors.add('Missing or invalid "id" field');
    }
    if (json['gridW'] is! int) {
      errors.add('Missing or invalid "gridW" field');
    }
    if (json['gridH'] is! int) {
      errors.add('Missing or invalid "gridH" field');
    }
    if (json['arrows'] is! List) {
      errors.add('Missing or invalid "arrows" field');
    } else {
      final arrows = json['arrows'] as List;
      for (int i = 0; i < arrows.length; i++) {
        if (arrows[i] is! Map<String, dynamic>) {
          errors.add('Arrow at index $i is not a valid object');
          continue;
        }
        final a = arrows[i] as Map<String, dynamic>;
        if (a['cells'] is! List) {
          errors.add('Arrow at index $i missing "cells" field');
        }
        if (a['dir'] is! String) {
          errors.add('Arrow at index $i missing "dir" field');
        } else {
          final dir = a['dir'] as String;
          if (!['u', 'd', 'l', 'r'].contains(dir)) {
            errors.add('Arrow at index $i has invalid direction "$dir"');
          }
        }
      }
    }

    return errors;
  }
}

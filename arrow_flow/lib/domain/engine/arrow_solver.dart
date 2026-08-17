import '../../data/models/arrow_model.dart';
import '../../data/models/level_model.dart';

/// The core puzzle engine implementing ray-cast blocked detection and solving.
///
/// This is pure Dart with zero Flutter dependencies, making it fully
/// unit-testable and reusable outside of the app (e.g. server-side QA).
class ArrowSolver {
  /// Checks whether an arrow is selectable (can be removed from the board).
  ///
  /// An arrow is selectable if and only if every cell strictly between
  /// its arrowhead and the board edge, along its exit direction ray,
  /// contains no cell belonging to another still-active arrow.
  /// Checks whether an arrow is selectable (can be removed from the board).
  static bool isSelectable(
    Arrow arrow,
    List<Arrow> activeArrows,
    int gridWidth,
    int gridHeight,
  ) {
    final (dx, dy) = arrow.direction.delta;
    final (hx, hy) = arrow.head;
    var cx = hx + dx;
    var cy = hy + dy;

    // Check if ray is clear to edge
    while (cx >= 0 && cx < gridWidth && cy >= 0 && cy < gridHeight) {
      for (final other in activeArrows) {
        if (other.id != arrow.id && other.cells.contains((cx, cy))) {
          return false;
        }
      }
      cx += dx;
      cy += dy;
    }
    return true;
  }

  /// Returns all currently selectable arrows from the active set.
  static List<Arrow> findAllSelectable(
    List<Arrow> activeArrows,
    int gridWidth,
    int gridHeight,
  ) {
    if (activeArrows.isEmpty) return const [];

    final grid = List.generate(gridHeight, (_) => List.filled(gridWidth, -1));
    for (final a in activeArrows) {
      for (final (x, y) in a.cells) {
        if (x >= 0 && x < gridWidth && y >= 0 && y < gridHeight) {
          grid[y][x] = a.id;
        }
      }
    }

    final selectable = <Arrow>[];
    for (final arrow in activeArrows) {
      final (dx, dy) = arrow.direction.delta;
      final (hx, hy) = arrow.head;
      var cx = hx + dx;
      var cy = hy + dy;
      bool clear = true;

      while (cx >= 0 && cx < gridWidth && cy >= 0 && cy < gridHeight) {
        final occupant = grid[cy][cx];
        if (occupant != -1 && occupant != arrow.id) {
          clear = false;
          break;
        }
        cx += dx;
        cy += dy;
      }

      if (clear) selectable.add(arrow);
    }
    return selectable;
  }

  /// Checks if a level is solvable by attempting a full clear.
  static bool isSolvable(Level level) {
    return _solveFast(List.of(level.arrows), level.gridWidth, level.gridHeight);
  }

  /// Fast confluent greedy solver.
  static bool _solveFast(
    List<Arrow> remaining,
    int gridWidth,
    int gridHeight,
  ) {
    final list = List<Arrow>.of(remaining);
    final grid = List.generate(gridHeight, (_) => List.filled(gridWidth, -1));
    for (final a in list) {
      for (final (x, y) in a.cells) {
        if (x >= 0 && x < gridWidth && y >= 0 && y < gridHeight) {
          grid[y][x] = a.id;
        }
      }
    }

    while (list.isNotEmpty) {
      Arrow? freeArrow;
      for (final arrow in list) {
        final (dx, dy) = arrow.direction.delta;
        final (hx, hy) = arrow.head;
        var cx = hx + dx;
        var cy = hy + dy;
        bool clear = true;

        while (cx >= 0 && cx < gridWidth && cy >= 0 && cy < gridHeight) {
          final occupant = grid[cy][cx];
          if (occupant != -1 && occupant != arrow.id) {
            clear = false;
            break;
          }
          cx += dx;
          cy += dy;
        }

        if (clear) {
          freeArrow = arrow;
          break;
        }
      }

      if (freeArrow == null) return false;

      // Remove from grid and list
      for (final (x, y) in freeArrow.cells) {
        if (x >= 0 && x < gridWidth && y >= 0 && y < gridHeight) {
          grid[y][x] = -1;
        }
      }
      list.remove(freeArrow);
    }
    return true;
  }

  /// Returns one valid removal order if the level is solvable, or null if not.
  static List<Arrow>? solve(Level level) {
    final list = List<Arrow>.of(level.arrows);
    final order = <Arrow>[];
    final grid = List.generate(level.gridHeight, (_) => List.filled(level.gridWidth, -1));
    for (final a in list) {
      for (final (x, y) in a.cells) {
        if (x >= 0 && x < level.gridWidth && y >= 0 && y < level.gridHeight) {
          grid[y][x] = a.id;
        }
      }
    }

    while (list.isNotEmpty) {
      Arrow? freeArrow;
      for (final arrow in list) {
        final (dx, dy) = arrow.direction.delta;
        final (hx, hy) = arrow.head;
        var cx = hx + dx;
        var cy = hy + dy;
        bool clear = true;

        while (cx >= 0 && cx < level.gridWidth && cy >= 0 && cy < level.gridHeight) {
          final occupant = grid[cy][cx];
          if (occupant != -1 && occupant != arrow.id) {
            clear = false;
            break;
          }
          cx += dx;
          cy += dy;
        }

        if (clear) {
          freeArrow = arrow;
          break;
        }
      }

      if (freeArrow == null) return null;

      for (final (x, y) in freeArrow.cells) {
        if (x >= 0 && x < level.gridWidth && y >= 0 && y < level.gridHeight) {
          grid[y][x] = -1;
        }
      }
      order.add(freeArrow);
      list.remove(freeArrow);
    }
    return order;
  }

  /// Checks whether a tap on a blocked arrow should cost a heart.
  ///
  /// Per the spec, tapping a blocked arrow resets the combo. Whether it
  /// also costs a heart depends on the mistakePenalty config setting.
  /// This method just determines if the arrow is genuinely blocked
  /// (its exit ray is obstructed by another arrow's cells).
  static bool isBlocked(
    Arrow arrow,
    List<Arrow> activeArrows,
    int gridWidth,
    int gridHeight,
  ) {
    return !isSelectable(arrow, activeArrows, gridWidth, gridHeight);
  }
}

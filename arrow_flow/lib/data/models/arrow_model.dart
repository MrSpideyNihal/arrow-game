/// Direction an arrow points and exits the board.
enum Direction {
  up('u'),
  down('d'),
  left('l'),
  right('r');

  final String code;
  const Direction(this.code);

  static Direction fromCode(String code) {
    return Direction.values.firstWhere(
      (d) => d.code == code,
      orElse: () => throw ArgumentError('Invalid direction code: $code'),
    );
  }

  /// Returns the (dx, dy) unit vector for this direction on the grid.
  /// Grid origin is top-left: x increases right, y increases down.
  (int, int) get delta => switch (this) {
    Direction.up => (0, -1),
    Direction.down => (0, 1),
    Direction.left => (-1, 0),
    Direction.right => (1, 0),
  };
}

/// A single arrow on the puzzle board.
///
/// Each arrow occupies a list of grid cells from tail to head,
/// and has a direction indicating where its arrowhead points
/// (and the direction it exits the board on removal).
class Arrow {
  final int id;
  final List<(int, int)> cells;
  final Direction direction;

  const Arrow({
    required this.id,
    required this.cells,
    required this.direction,
  });

  /// The arrowhead cell (last cell in the path).
  (int, int) get head => cells.last;

  /// The tail cell (first cell in the path).
  (int, int) get tail => cells.first;

  /// Number of cells this arrow occupies.
  int get length => cells.length;

  /// Returns a set of all cells this arrow occupies for fast lookup.
  Set<(int, int)> get cellSet => cells.toSet();

  /// Deserialize from the compact JSON format:
  /// { "cells": [[3,2],[3,3],[3,4]], "dir": "d" }
  factory Arrow.fromJson(Map<String, dynamic> json, int id) {
    final rawCells = json['cells'] as List;
    final cells = rawCells.map((c) {
      final pair = c as List;
      return (pair[0] as int, pair[1] as int);
    }).toList();
    final direction = Direction.fromCode(json['dir'] as String);
    return Arrow(id: id, cells: cells, direction: direction);
  }

  /// Serialize to the compact JSON format.
  Map<String, dynamic> toJson() {
    return {
      'cells': cells.map((c) => [c.$1, c.$2]).toList(),
      'dir': direction.code,
    };
  }

  @override
  String toString() => 'Arrow($id, head=$head, dir=${direction.code})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Arrow && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

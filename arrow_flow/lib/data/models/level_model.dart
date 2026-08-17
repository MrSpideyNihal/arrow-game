import 'arrow_model.dart';

/// A single puzzle level.
///
/// Contains the grid dimensions and the set of arrows to be cleared.
/// Levels are stored in compact JSON and loaded from bundled asset packs.
class Level {
  final int id;
  final String difficulty;
  final int gridWidth;
  final int gridHeight;
  final List<Arrow> arrows;

  const Level({
    required this.id,
    required this.difficulty,
    required this.gridWidth,
    required this.gridHeight,
    required this.arrows,
  });

  /// Total number of arrows in this level.
  int get arrowCount => arrows.length;

  /// Deserialize from compact JSON.
  factory Level.fromJson(Map<String, dynamic> json) {
    final rawArrows = json['arrows'] as List;
    final arrows = <Arrow>[];
    for (int i = 0; i < rawArrows.length; i++) {
      arrows.add(Arrow.fromJson(rawArrows[i] as Map<String, dynamic>, i));
    }
    return Level(
      id: json['id'] as int,
      difficulty: json['difficulty'] as String? ?? 'normal',
      gridWidth: json['gridW'] as int,
      gridHeight: json['gridH'] as int,
      arrows: arrows,
    );
  }

  /// Serialize to compact JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'difficulty': difficulty,
      'gridW': gridWidth,
      'gridH': gridHeight,
      'arrows': arrows.map((a) => a.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'Level($id, ${gridWidth}x$gridHeight, $arrowCount arrows, $difficulty)';
}

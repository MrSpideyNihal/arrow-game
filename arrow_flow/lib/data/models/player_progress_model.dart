/// Record of player progress for a single level.
class LevelProgress {
  final int levelId;
  final int stars; // 0..3
  final int bestCombo;
  final bool flowStateReached;
  final bool isCompleted;

  const LevelProgress({
    required this.levelId,
    required this.stars,
    required this.bestCombo,
    required this.flowStateReached,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'stars': stars,
        'bestCombo': bestCombo,
        'flowStateReached': flowStateReached,
        'isCompleted': isCompleted,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelId: json['levelId'] as int,
      stars: json['stars'] as int? ?? 0,
      bestCombo: json['bestCombo'] as int? ?? 0,
      flowStateReached: json['flowStateReached'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

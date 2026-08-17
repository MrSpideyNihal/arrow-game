import '../../core/services/storage_service.dart';
import '../models/player_progress_model.dart';

/// Repository managing player level progress via [StorageService].
class ProgressRepository {
  final StorageService storageService;

  ProgressRepository({required this.storageService});

  /// Loads progress for a specific level.
  LevelProgress getLevelProgress(int levelId) {
    final raw = storageService.getLevelProgress(levelId);
    if (raw == null) {
      return LevelProgress(
        levelId: levelId,
        stars: 0,
        bestCombo: 0,
        flowStateReached: false,
        isCompleted: false,
      );
    }
    return LevelProgress.fromJson(raw);
  }

  /// Saves progress for a level if it improves on previous stars/combos.
  Future<LevelProgress> updateProgress({
    required int levelId,
    required int stars,
    required int bestCombo,
    required bool flowStateReached,
  }) async {
    final existing = getLevelProgress(levelId);
    final newStars = stars > existing.stars ? stars : existing.stars;
    final newCombo =
        bestCombo > existing.bestCombo ? bestCombo : existing.bestCombo;
    final newFlow = flowStateReached || existing.flowStateReached;

    final updated = LevelProgress(
      levelId: levelId,
      stars: newStars,
      bestCombo: newCombo,
      flowStateReached: newFlow,
      isCompleted: true,
    );

    await storageService.saveLevelProgress(levelId, updated.toJson());
    return updated;
  }

  /// Calculates total stars earned across all levels.
  int getTotalStars(int maxLevelId) {
    int total = 0;
    for (int i = 1; i <= maxLevelId; i++) {
      final p = getLevelProgress(i);
      total += p.stars;
    }
    return total;
  }
}

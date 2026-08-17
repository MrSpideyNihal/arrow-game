import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/arrow_model.dart';
import '../../data/models/level_model.dart';
import '../../data/repositories/progress_repository.dart';
import '../../core/services/storage_service.dart';
import '../../domain/engine/arrow_solver.dart';
import '../../domain/systems/combo_engine.dart';
import '../../main.dart';

/// Parameter object for timer mode level sessions.
class TimerLevelArgs {
  final Level level;
  final int timerSeconds;

  const TimerLevelArgs({required this.level, this.timerSeconds = 45});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerLevelArgs &&
          runtimeType == other.runtimeType &&
          level.id == other.level.id &&
          timerSeconds == other.timerSeconds;

  @override
  int get hashCode => level.id.hashCode ^ timerSeconds.hashCode;
}

/// The full mutable state of an active gameplay session.
class GameState {
  final Level level;
  final List<Arrow> activeArrows;
  final List<Arrow> selectableArrows;
  final int livesRemaining;
  final int hintsRemaining;
  final int bombsRemaining;
  final int radarsRemaining;
  final int undoRemaining;
  final int mistakes;
  final int removedCount;
  final ComboState comboState;
  final int maxComboReached;
  final bool isComplete;
  final bool isGameOver;
  // Timer Mode fields
  final bool isTimerMode;
  final int timerSecondsLeft;
  final int timerSecondsTotal;
  final bool isTimeUp;
  final List<Arrow> removedHistory;

  const GameState({
    required this.level,
    required this.activeArrows,
    required this.selectableArrows,
    required this.livesRemaining,
    required this.hintsRemaining,
    this.bombsRemaining = 2,
    this.radarsRemaining = 2,
    this.undoRemaining = 2,
    required this.mistakes,
    required this.removedCount,
    required this.comboState,
    required this.maxComboReached,
    required this.isComplete,
    required this.isGameOver,
    this.isTimerMode = false,
    this.timerSecondsLeft = 45,
    this.timerSecondsTotal = 45,
    this.isTimeUp = false,
    this.removedHistory = const [],
  });

  int get totalArrows => level.arrowCount;
  int get arrowsRemaining => activeArrows.length;
  bool get canUndo => removedHistory.isNotEmpty && undoRemaining > 0;

  GameState copyWith({
    List<Arrow>? activeArrows,
    List<Arrow>? selectableArrows,
    int? livesRemaining,
    int? hintsRemaining,
    int? bombsRemaining,
    int? radarsRemaining,
    int? undoRemaining,
    int? mistakes,
    int? removedCount,
    ComboState? comboState,
    int? maxComboReached,
    bool? isComplete,
    bool? isGameOver,
    bool? isTimerMode,
    int? timerSecondsLeft,
    int? timerSecondsTotal,
    bool? isTimeUp,
    List<Arrow>? removedHistory,
  }) {
    return GameState(
      level: level,
      activeArrows: activeArrows ?? this.activeArrows,
      selectableArrows: selectableArrows ?? this.selectableArrows,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      bombsRemaining: bombsRemaining ?? this.bombsRemaining,
      radarsRemaining: radarsRemaining ?? this.radarsRemaining,
      undoRemaining: undoRemaining ?? this.undoRemaining,
      mistakes: mistakes ?? this.mistakes,
      removedCount: removedCount ?? this.removedCount,
      comboState: comboState ?? this.comboState,
      maxComboReached: maxComboReached ?? this.maxComboReached,
      isComplete: isComplete ?? this.isComplete,
      isGameOver: isGameOver ?? this.isGameOver,
      isTimerMode: isTimerMode ?? this.isTimerMode,
      timerSecondsLeft: timerSecondsLeft ?? this.timerSecondsLeft,
      timerSecondsTotal: timerSecondsTotal ?? this.timerSecondsTotal,
      isTimeUp: isTimeUp ?? this.isTimeUp,
      removedHistory: removedHistory ?? this.removedHistory,
    );
  }
}

/// Manages the gameplay session state. Created fresh for each level attempt.
class GameStateNotifier extends StateNotifier<GameState> {
  final ComboEngine _comboEngine;
  final StorageService _storage = StorageService();

  GameStateNotifier(Level level, {bool isTimerMode = false, int timerSeconds = 45})
      : _comboEngine = ComboEngine(
          comboWindowMs: appConfig.gameplay.comboWindowMs,
          thresholds: appConfig.gameplay.comboTierThresholds,
        ),
        super(GameState(
          level: level,
          activeArrows: List.of(level.arrows),
          selectableArrows: ArrowSolver.findAllSelectable(
            level.arrows,
            level.gridWidth,
            level.gridHeight,
          ),
          livesRemaining: isTimerMode ? 99 : appConfig.gameplay.startingLives,
          hintsRemaining: isTimerMode ? 0 : StorageService().getBoosterCount(StorageService.boosterHints, defaultValue: 3),
          bombsRemaining: isTimerMode ? 0 : StorageService().getBoosterCount(StorageService.boosterBombs, defaultValue: 2),
          radarsRemaining: isTimerMode ? 0 : StorageService().getBoosterCount(StorageService.boosterRadars, defaultValue: 2),
          undoRemaining: 0,
          mistakes: 0,
          removedCount: 0,
          comboState: ComboState.initial(),
          maxComboReached: 0,
          isComplete: false,
          isGameOver: false,
          isTimerMode: isTimerMode,
          timerSecondsLeft: timerSeconds,
          timerSecondsTotal: timerSeconds,
          isTimeUp: false,
          removedHistory: const [],
        ));

  /// Tick the timer down by 1 second.
  void tickTimer() {
    if (!state.isTimerMode || state.isComplete || state.isTimeUp) return;
    final newSecs = state.timerSecondsLeft - 1;
    if (newSecs <= 0) {
      state = state.copyWith(timerSecondsLeft: 0, isTimeUp: true, isGameOver: true);
    } else {
      state = state.copyWith(timerSecondsLeft: newSecs);
    }
  }

  /// Add extra seconds to timer (e.g. from watching a rewarded ad).
  void addTimerSeconds(int seconds) {
    if (!state.isTimerMode) return;
    final updatedSecs = state.timerSecondsLeft + seconds;
    state = state.copyWith(
      timerSecondsLeft: updatedSecs,
      isTimeUp: false,
      isGameOver: false,
    );
  }

  /// Checks and resets combo multiplier if combo window has expired.
  void checkComboWindow() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedCombo =
        _comboEngine.checkWindowExpiration(state.comboState, now);
    if (updatedCombo.comboCount != state.comboState.comboCount) {
      state = state.copyWith(comboState: updatedCombo);
    }
  }

  /// Called when a player taps an arrow.
  /// Returns true if the arrow was successfully removed.
  bool tapArrow(Arrow arrow) {
    if (state.isComplete || state.isGameOver || state.isTimeUp) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final isSelectable = state.selectableArrows.contains(arrow);

    if (isSelectable) {
      // Valid tap
      final newComboState = _comboEngine.recordHit(state.comboState, now);
      final newMaxCombo = newComboState.comboCount > state.maxComboReached
          ? newComboState.comboCount
          : state.maxComboReached;

      final newActive = List.of(state.activeArrows)..remove(arrow);
      final newSelectable = ArrowSolver.findAllSelectable(
        newActive,
        state.level.gridWidth,
        state.level.gridHeight,
      );

      final newHistory = List.of(state.removedHistory)..add(arrow);

      state = state.copyWith(
        activeArrows: newActive,
        selectableArrows: newSelectable,
        removedCount: state.removedCount + 1,
        comboState: newComboState,
        maxComboReached: newMaxCombo,
        isComplete: newActive.isEmpty,
        removedHistory: newHistory,
      );
      return true;
    } else {
      // Invalid tap
      final newComboState = _comboEngine.recordMiss(state.comboState);

      if (state.isTimerMode) {
        // In timer mode — wrong tap = 3 second penalty
        final penalizedSecs = (state.timerSecondsLeft - 3).clamp(0, 999);
        state = state.copyWith(
          mistakes: state.mistakes + 1,
          comboState: newComboState,
          timerSecondsLeft: penalizedSecs,
          isTimeUp: penalizedSecs <= 0,
          isGameOver: penalizedSecs <= 0,
        );
        return false;
      } else {
        // Normal mode — lose a life
        final newLives = state.livesRemaining - 1;
        state = state.copyWith(
          livesRemaining: newLives,
          mistakes: state.mistakes + 1,
          comboState: newComboState,
          isGameOver: newLives <= 0,
        );
      }
      return false;
    }
  }

  /// Blast & destroy any arrow using a Bomb booster
  bool blastArrow(Arrow arrow) {
    if (state.bombsRemaining <= 0 || !state.activeArrows.contains(arrow)) return false;

    final newActive = List.of(state.activeArrows)..remove(arrow);
    final newSelectable = ArrowSolver.findAllSelectable(
      newActive,
      state.level.gridWidth,
      state.level.gridHeight,
    );
    final newHistory = List.of(state.removedHistory)..add(arrow);
    final newBombs = state.bombsRemaining - 1;

    _storage.saveBoosterCount(StorageService.boosterBombs, newBombs);

    state = state.copyWith(
      activeArrows: newActive,
      selectableArrows: newSelectable,
      bombsRemaining: newBombs,
      removedCount: state.removedCount + 1,
      isComplete: newActive.isEmpty,
      removedHistory: newHistory,
    );
    return true;
  }

  /// Undo last removed arrow
  bool undo() {
    if (!state.canUndo) return false;

    final lastArrow = state.removedHistory.last;
    final newHistory = List.of(state.removedHistory)..removeLast();
    final newActive = List.of(state.activeArrows)..add(lastArrow);
    final newSelectable = ArrowSolver.findAllSelectable(
      newActive,
      state.level.gridWidth,
      state.level.gridHeight,
    );

    state = state.copyWith(
      activeArrows: newActive,
      selectableArrows: newSelectable,
      undoRemaining: state.undoRemaining - 1,
      removedCount: (state.removedCount - 1).clamp(0, 9999),
      isComplete: false,
      removedHistory: newHistory,
    );
    return true;
  }

  /// Use a radar scan (reveals all selectable arrows)
  bool useRadar() {
    if (state.radarsRemaining <= 0) return false;
    final newRadars = state.radarsRemaining - 1;
    _storage.saveBoosterCount(StorageService.boosterRadars, newRadars);
    state = state.copyWith(radarsRemaining: newRadars);
    return true;
  }

  /// Use a hint.
  Arrow? useHint() {
    if (state.hintsRemaining <= 0 || state.selectableArrows.isEmpty) {
      return null;
    }

    final newHints = state.hintsRemaining - 1;
    _storage.saveBoosterCount(StorageService.boosterHints, newHints);

    state = state.copyWith(
      hintsRemaining: newHints,
    );

    return state.selectableArrows.first;
  }

  /// Add booster from in-game quick purchase
  void addBooster(String key, int amount) {
    if (key == StorageService.boosterHints) {
      final updated = state.hintsRemaining + amount;
      state = state.copyWith(hintsRemaining: updated);
      _storage.saveBoosterCount(StorageService.boosterHints, updated);
    } else if (key == StorageService.boosterBombs) {
      final updated = state.bombsRemaining + amount;
      state = state.copyWith(bombsRemaining: updated);
      _storage.saveBoosterCount(StorageService.boosterBombs, updated);
    } else if (key == StorageService.boosterRadars) {
      final updated = state.radarsRemaining + amount;
      state = state.copyWith(radarsRemaining: updated);
      _storage.saveBoosterCount(StorageService.boosterRadars, updated);
    }
  }

  /// Revive after game over.
  void revive() {
    if (!state.isGameOver) return;
    state = state.copyWith(
      livesRemaining: 1,
      isGameOver: false,
      isTimeUp: false,
    );
  }

  /// Resets the board.
  void reset() {
    state = GameState(
      level: state.level,
      activeArrows: List.of(state.level.arrows),
      selectableArrows: ArrowSolver.findAllSelectable(
        state.level.arrows,
        state.level.gridWidth,
        state.level.gridHeight,
      ),
      livesRemaining: state.isTimerMode ? 99 : appConfig.gameplay.startingLives,
      hintsRemaining: state.isTimerMode ? 0 : _storage.getBoosterCount(StorageService.boosterHints, defaultValue: 3),
      bombsRemaining: state.isTimerMode ? 0 : _storage.getBoosterCount(StorageService.boosterBombs, defaultValue: 2),
      radarsRemaining: state.isTimerMode ? 0 : _storage.getBoosterCount(StorageService.boosterRadars, defaultValue: 2),
      undoRemaining: 0,
      mistakes: 0,
      removedCount: 0,
      comboState: ComboState.initial(),
      maxComboReached: 0,
      isComplete: false,
      isGameOver: false,
      isTimerMode: state.isTimerMode,
      timerSecondsLeft: state.timerSecondsTotal,
      timerSecondsTotal: state.timerSecondsTotal,
      isTimeUp: false,
      removedHistory: const [],
    );
  }
}

/// Provider family for normal level gameplay.
final gameStateProvider =
    StateNotifierProvider.family<GameStateNotifier, GameState, Level>(
  (ref, level) => GameStateNotifier(level),
);

/// Provider family for timer mode gameplay.
final timerGameStateProvider =
    StateNotifierProvider.family<GameStateNotifier, GameState, TimerLevelArgs>(
  (ref, args) => GameStateNotifier(
    args.level,
    isTimerMode: true,
    timerSeconds: args.timerSeconds,
  ),
);

/// Player progress data model.
class PlayerProgressState {
  final int unlockedLevelId;
  final int totalStars;

  const PlayerProgressState({
    required this.unlockedLevelId,
    required this.totalStars,
  });
}

/// Notifier for managing player level progress reactively.
class PlayerProgressNotifier extends StateNotifier<PlayerProgressState> {
  final ProgressRepository _repo;

  PlayerProgressNotifier(this._repo)
      : super(const PlayerProgressState(unlockedLevelId: 1, totalStars: 0)) {
    loadProgress();
  }

  void loadProgress() {
    int totalStars = _repo.getTotalStars(500);
    int unlocked = 1;

    for (int i = 1; i <= 500; i++) {
      final p = _repo.getLevelProgress(i);
      if (p.isCompleted) {
        unlocked = i + 1;
      } else {
        break;
      }
    }

    state = PlayerProgressState(
      unlockedLevelId: unlocked.clamp(1, 500),
      totalStars: totalStars,
    );
  }

  Future<void> completeLevel(int levelId, int mistakes) async {
    final stars = (3 - mistakes).clamp(1, 3);
    await _repo.updateProgress(
      levelId: levelId,
      stars: stars,
      bestCombo: 0,
      flowStateReached: false,
    );
    loadProgress();
  }
}

/// Provider for player level progress.
final progressProvider =
    StateNotifierProvider<PlayerProgressNotifier, PlayerProgressState>((ref) {
  final storage = StorageService();
  final repo = ProgressRepository(storageService: storage);
  return PlayerProgressNotifier(repo);
});

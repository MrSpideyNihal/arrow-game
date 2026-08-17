import 'package:hive_flutter/hive_flutter.dart';

/// Wrapper around Hive for local persistence of progress and economy data.
/// Safe against late-initialization and type-casting errors.
class StorageService {
  static const String _progressBox = 'progress';
  static const String _economyBox = 'economy';
  static const String _settingsBox = 'settings';

  Future<void> initialize() async {
    await Hive.openBox(_progressBox);
    await Hive.openBox(_economyBox);
    await Hive.openBox(_settingsBox);

    // Set initial defaults only on very first launch
    if (getSetting<String>('active_theme') == null) {
      await saveSetting('active_theme', 'theme_default');
    }
    if (getSetting<String>('active_skin') == null) {
      await saveSetting('active_skin', 'arrow_default');
    }
  }

  Box<dynamic>? get _progress =>
      Hive.isBoxOpen(_progressBox) ? Hive.box(_progressBox) : null;

  Box<dynamic>? get _economy =>
      Hive.isBoxOpen(_economyBox) ? Hive.box(_economyBox) : null;

  Box<dynamic>? get _settings =>
      Hive.isBoxOpen(_settingsBox) ? Hive.box(_settingsBox) : null;

  // Progress operations
  Future<void> saveLevelProgress(int levelId, Map<String, dynamic> data) async {
    await _progress?.put('level_$levelId', data);
  }

  Map<String, dynamic>? getLevelProgress(int levelId) {
    try {
      final data = _progress?.get('level_$levelId');
      if (data == null) return null;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Economy operations
  Future<void> saveSparksBalance(int balance) async {
    await _economy?.put('sparks', balance);
  }

  int getSparksBalance() {
    try {
      final val = _economy?.get('sparks', defaultValue: 0);
      if (val is int) return val;
      if (val is num) return val.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> saveUnlockedCosmetics(List<String> ids) async {
    await _economy?.put('unlocked_cosmetics', ids);
  }

  List<String> getUnlockedCosmetics() {
    try {
      final data = _economy?.get('unlocked_cosmetics');
      if (data == null) return [];
      if (data is List) {
        return List<String>.from(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Booster inventory operations
  static const String boosterHints = 'booster_hints';
  static const String boosterBombs = 'booster_bombs';
  static const String boosterRadars = 'booster_radars';

  int getBoosterCount(String key, {int defaultValue = 3}) {
    try {
      final val = _economy?.get(key, defaultValue: defaultValue);
      if (val is int) return val;
      if (val is num) return val.toInt();
      return defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  Future<void> saveBoosterCount(String key, int count) async {
    await _economy?.put(key, count.clamp(0, 999));
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    await _settings?.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      final val = _settings?.get(key, defaultValue: defaultValue);
      if (val is T) return val;
      return defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  // Reset all progress (settings screen)
  Future<void> resetAllProgress() async {
    await _progress?.clear();
    await _economy?.clear();
  }
}

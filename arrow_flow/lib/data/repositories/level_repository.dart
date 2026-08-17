import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';
import '../../domain/engine/level_generator.dart';
import '../models/level_model.dart';

/// Repository for loading bundled level packs and procedurally generating
/// long-tail levels beyond the pre-baked count on demand.
class LevelRepository {
  final LevelsConfig config;

  final Map<int, Level> _levelCache = {};
  bool _isBundledLoaded = false;

  LevelRepository({required this.config});

  /// Loads bundled level pack from asset JSON.
  Future<void> loadBundledPack() async {
    if (_isBundledLoaded) return;
    try {
      final jsonString =
          await rootBundle.loadString(config.bundledPackFile);
      final List<dynamic> rawList = jsonDecode(jsonString);
      for (final raw in rawList) {
        final level = Level.fromJson(raw as Map<String, dynamic>);
        _levelCache[level.id] = level;
      }
      _isBundledLoaded = true;
    } catch (_) {
      // If asset load fails or is empty, fall back to procedural generator
      _isBundledLoaded = true;
    }
  }

  /// Gets level by ID.
  /// If the level is bundled, returns it from cache.
  /// If beyond bundled count, generates it on-demand deterministically and caches it.
  Future<Level> getLevel(int levelId) async {
    if (!_isBundledLoaded) {
      await loadBundledPack();
    }

    if (_levelCache.containsKey(levelId)) {
      return _levelCache[levelId]!;
    }

    // Procedural generation for long-tail levels (101..1000+)
    final level = LevelGenerator.generate(
      levelId,
      config.difficultyCurveSeed,
    );
    if (config.cacheGeneratedLevelsLocally) {
      _levelCache[levelId] = level;
    }
    return level;
  }
}

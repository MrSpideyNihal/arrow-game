import 'dart:convert';
import 'package:flutter/services.dart';

/// Typed configuration loaded from config/game_config.json at app boot.
/// This is the single source of truth for all tunable values in the app.
class AppConfig {
  final AppInfo app;
  final FeatureFlags featureFlags;
  final AdsConfig ads;
  final MonetizationConfig monetization;
  final GameplayConfig gameplay;
  final EconomyConfig economy;
  final LevelsConfig levels;
  final ThemeConfig theme;
  final AudioConfig audio;

  const AppConfig({
    required this.app,
    required this.featureFlags,
    required this.ads,
    required this.monetization,
    required this.gameplay,
    required this.economy,
    required this.levels,
    required this.theme,
    required this.audio,
  });

  /// Loads and parses the config file from bundled assets.
  static Future<AppConfig> load() async {
    final jsonString = await rootBundle.loadString('config/game_config.json');
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return AppConfig.fromJson(json);
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      app: AppInfo.fromJson(json['app'] as Map<String, dynamic>),
      featureFlags:
          FeatureFlags.fromJson(json['featureFlags'] as Map<String, dynamic>),
      ads: AdsConfig.fromJson(json['ads'] as Map<String, dynamic>),
      monetization: MonetizationConfig.fromJson(
          json['monetization'] as Map<String, dynamic>),
      gameplay:
          GameplayConfig.fromJson(json['gameplay'] as Map<String, dynamic>),
      economy:
          EconomyConfig.fromJson(json['economy'] as Map<String, dynamic>),
      levels: LevelsConfig.fromJson(json['levels'] as Map<String, dynamic>),
      theme: ThemeConfig.fromJson(json['theme'] as Map<String, dynamic>),
      audio: AudioConfig.fromJson(json['audio'] as Map<String, dynamic>),
    );
  }
}

class AppInfo {
  final String name;
  final String packageId;
  final String version;
  final int buildNumber;
  final String supportEmail;
  final String privacyPolicyUrl;
  final String termsUrl;

  const AppInfo({
    required this.name,
    required this.packageId,
    required this.version,
    required this.buildNumber,
    required this.supportEmail,
    required this.privacyPolicyUrl,
    required this.termsUrl,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      name: json['name'] as String,
      packageId: json['packageId'] as String,
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      supportEmail: json['supportEmail'] as String,
      privacyPolicyUrl: json['privacyPolicyUrl'] as String,
      termsUrl: json['termsUrl'] as String,
    );
  }
}

class FeatureFlags {
  final bool dailyChallenge;
  final bool comboSystem;
  final bool colorLockedArrows;
  final bool cosmeticShop;

  const FeatureFlags({
    required this.dailyChallenge,
    required this.comboSystem,
    required this.colorLockedArrows,
    required this.cosmeticShop,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      dailyChallenge: json['dailyChallenge'] as bool,
      comboSystem: json['comboSystem'] as bool,
      colorLockedArrows: json['colorLockedArrows'] as bool,
      cosmeticShop: json['cosmeticShop'] as bool,
    );
  }
}

class AdsConfig {
  final String provider;
  final bool testMode;
  final bool enableAds;
  final String androidAppId;
  final String bannerAdUnitId;
  final String rewardedAdUnitId;
  final List<String> bannerPlacements;
  final List<String> rewardedTriggers;

  /// Google's official test ad unit IDs for safe development use.
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';

  const AdsConfig({
    required this.provider,
    required this.testMode,
    required this.enableAds,
    required this.androidAppId,
    required this.bannerAdUnitId,
    required this.rewardedAdUnitId,
    required this.bannerPlacements,
    required this.rewardedTriggers,
  });

  /// Returns the effective banner ad unit ID, using test IDs when testMode is on.
  String get effectiveBannerAdUnitId =>
      testMode ? testBannerAdUnitId : bannerAdUnitId;

  /// Returns the effective rewarded ad unit ID, using test IDs when testMode is on.
  String get effectiveRewardedAdUnitId =>
      testMode ? testRewardedAdUnitId : rewardedAdUnitId;

  /// Returns the effective app ID, using test ID when testMode is on.
  String get effectiveAndroidAppId =>
      testMode ? testAndroidAppId : androidAppId;

  factory AdsConfig.fromJson(Map<String, dynamic> json) {
    return AdsConfig(
      provider: json['provider'] as String,
      testMode: json['testMode'] as bool,
      enableAds: json['enableAds'] as bool,
      androidAppId: json['androidAppId'] as String,
      bannerAdUnitId: json['bannerAdUnitId'] as String,
      rewardedAdUnitId: json['rewardedAdUnitId'] as String,
      bannerPlacements: (json['bannerPlacements'] as List).cast<String>(),
      rewardedTriggers: (json['rewardedTriggers'] as List).cast<String>(),
    );
  }
}

class MonetizationConfig {
  final String removeAdsProductId;
  final bool removeAdsHidesBanner;

  const MonetizationConfig({
    required this.removeAdsProductId,
    required this.removeAdsHidesBanner,
  });

  factory MonetizationConfig.fromJson(Map<String, dynamic> json) {
    return MonetizationConfig(
      removeAdsProductId: json['removeAdsProductId'] as String,
      removeAdsHidesBanner: json['removeAdsHidesBanner'] as bool,
    );
  }
}

class GameplayConfig {
  final int startingLives;
  final int startingHints;
  final int comboWindowMs;
  final List<int> comboTierThresholds;
  final String mistakePenalty;
  final bool secondWindEnabled;
  final int secondWindCostSparks;

  const GameplayConfig({
    required this.startingLives,
    required this.startingHints,
    required this.comboWindowMs,
    required this.comboTierThresholds,
    required this.mistakePenalty,
    required this.secondWindEnabled,
    required this.secondWindCostSparks,
  });

  factory GameplayConfig.fromJson(Map<String, dynamic> json) {
    return GameplayConfig(
      startingLives: json['startingLives'] as int,
      startingHints: json['startingHints'] as int,
      comboWindowMs: json['comboWindowMs'] as int,
      comboTierThresholds:
          (json['comboTierThresholds'] as List).cast<int>(),
      mistakePenalty: json['mistakePenalty'] as String,
      secondWindEnabled: json['secondWindEnabled'] as bool,
      secondWindCostSparks: json['secondWindCostSparks'] as int,
    );
  }
}

class EconomyConfig {
  final int sparksPerStar;
  final int sparksPerFlowState;
  final int sparksPerDailyChallenge;
  final int rewardedAdSparksBonus;
  final int hintCostSparks;

  const EconomyConfig({
    required this.sparksPerStar,
    required this.sparksPerFlowState,
    required this.sparksPerDailyChallenge,
    required this.rewardedAdSparksBonus,
    required this.hintCostSparks,
  });

  factory EconomyConfig.fromJson(Map<String, dynamic> json) {
    return EconomyConfig(
      sparksPerStar: json['sparksPerStar'] as int,
      sparksPerFlowState: json['sparksPerFlowState'] as int,
      sparksPerDailyChallenge: json['sparksPerDailyChallenge'] as int,
      rewardedAdSparksBonus: json['rewardedAdSparksBonus'] as int,
      hintCostSparks: json['hintCostSparks'] as int,
    );
  }
}

class LevelsConfig {
  final int bundledCount;
  final String bundledPackFile;
  final int generatedTargetCount;
  final int difficultyCurveSeed;
  final bool cacheGeneratedLevelsLocally;

  const LevelsConfig({
    required this.bundledCount,
    required this.bundledPackFile,
    required this.generatedTargetCount,
    required this.difficultyCurveSeed,
    required this.cacheGeneratedLevelsLocally,
  });

  factory LevelsConfig.fromJson(Map<String, dynamic> json) {
    return LevelsConfig(
      bundledCount: json['bundledCount'] as int,
      bundledPackFile: json['bundledPackFile'] as String,
      generatedTargetCount: json['generatedTargetCount'] as int,
      difficultyCurveSeed: json['difficultyCurveSeed'] as int,
      cacheGeneratedLevelsLocally:
          json['cacheGeneratedLevelsLocally'] as bool,
    );
  }
}

class ThemeConfig {
  final String style;
  final ThemeColors light;
  final ThemeColors dark;
  final String defaultMode;

  const ThemeConfig({
    required this.style,
    required this.light,
    required this.dark,
    required this.defaultMode,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      style: json['style'] as String,
      light: ThemeColors.fromJson(json['light'] as Map<String, dynamic>),
      dark: ThemeColors.fromJson(json['dark'] as Map<String, dynamic>),
      defaultMode: json['defaultMode'] as String,
    );
  }
}

class ThemeColors {
  final String background;
  final String surface;
  final String arrowPrimary;
  final String accent;
  final String textPrimary;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.arrowPrimary,
    required this.accent,
    required this.textPrimary,
  });

  factory ThemeColors.fromJson(Map<String, dynamic> json) {
    return ThemeColors(
      background: json['background'] as String,
      surface: json['surface'] as String,
      arrowPrimary: json['arrowPrimary'] as String,
      accent: json['accent'] as String,
      textPrimary: json['textPrimary'] as String,
    );
  }
}

class AudioConfig {
  final bool sfxEnabledDefault;
  final bool musicEnabledDefault;
  final bool hapticsEnabledDefault;

  const AudioConfig({
    required this.sfxEnabledDefault,
    required this.musicEnabledDefault,
    required this.hapticsEnabledDefault,
  });

  factory AudioConfig.fromJson(Map<String, dynamic> json) {
    return AudioConfig(
      sfxEnabledDefault: json['sfxEnabledDefault'] as bool,
      musicEnabledDefault: json['musicEnabledDefault'] as bool,
      hapticsEnabledDefault: json['hapticsEnabledDefault'] as bool,
    );
  }
}

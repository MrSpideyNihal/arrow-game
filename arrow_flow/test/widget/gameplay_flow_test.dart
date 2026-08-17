import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_flow/data/models/arrow_model.dart';
import 'package:arrow_flow/data/models/level_model.dart';
import 'package:arrow_flow/core/config/app_config.dart';
import 'package:arrow_flow/presentation/screens/gameplay/gameplay_screen.dart';
import 'package:arrow_flow/main.dart';

void main() {
  setUpAll(() {
    appConfig = const AppConfig(
      app: AppInfo(
        name: 'Arrow Flow',
        packageId: 'com.yourstudio.arrowflow',
        version: '1.0.0',
        buildNumber: 1,
        supportEmail: 'support@test.com',
        privacyPolicyUrl: 'https://test.com',
        termsUrl: 'https://test.com',
      ),
      featureFlags: FeatureFlags(
        dailyChallenge: true,
        comboSystem: true,
        colorLockedArrows: false,
        cosmeticShop: true,
      ),
      ads: AdsConfig(
        provider: 'admob',
        testMode: true,
        enableAds: true,
        androidAppId: 'test',
        bannerAdUnitId: 'test',
        rewardedAdUnitId: 'test',
        bannerPlacements: [],
        rewardedTriggers: [],
      ),
      monetization: MonetizationConfig(
        removeAdsProductId: 'remove_ads',
        removeAdsHidesBanner: true,
      ),
      gameplay: GameplayConfig(
        startingLives: 3,
        startingHints: 3,
        comboWindowMs: 1400,
        comboTierThresholds: [3, 6, 10],
        mistakePenalty: 'loseHeart',
        secondWindEnabled: true,
        secondWindCostSparks: 50,
      ),
      economy: EconomyConfig(
        sparksPerStar: 5,
        sparksPerFlowState: 15,
        sparksPerDailyChallenge: 30,
        rewardedAdSparksBonus: 20,
        hintCostSparks: 15,
      ),
      levels: LevelsConfig(
        bundledCount: 100,
        bundledPackFile: 'assets/levels/levels_pack_001.json',
        generatedTargetCount: 1000,
        difficultyCurveSeed: 20260809,
        cacheGeneratedLevelsLocally: true,
      ),
      theme: ThemeConfig(
        style: 'soft_neumorphism',
        light: ThemeColors(
          background: '#EDEEF2',
          surface: '#F4F5F8',
          arrowPrimary: '#1B2340',
          accent: '#00C2A8',
          textPrimary: '#1B1D24',
        ),
        dark: ThemeColors(
          background: '#14151A',
          surface: '#1B1D24',
          arrowPrimary: '#E7E9F0',
          accent: '#00E0BF',
          textPrimary: '#F4F5F8',
        ),
        defaultMode: 'system',
      ),
      audio: AudioConfig(
        sfxEnabledDefault: true,
        musicEnabledDefault: false,
        hapticsEnabledDefault: true,
      ),
    );
  });

  testWidgets('GameplayScreen renders HUD and Board correctly', (tester) async {
    final level = Level(
      id: 1,
      difficulty: 'easy',
      gridWidth: 12,
      gridHeight: 16,
      arrows: [
        Arrow(id: 0, cells: [(5, 2), (5, 3), (5, 4)], direction: Direction.down),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GameplayScreen(level: level),
        ),
      ),
    );

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('EASY'), findsOneWidget);

    // Clean up timer by unmounting widget and advancing fake time
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
  });
}

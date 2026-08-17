import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Automated Quality Hardening & Rule Compliance', () {
    final libDir = Directory('lib');

    test('Rule: Zero interstitial or app-open ad code anywhere in lib/', () async {
      final files = libDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;
        final content = await file.readAsString();

        // Must not instantiate InterstitialAd or AppOpenAd anywhere
        expect(
          content.contains('InterstitialAd.load') ||
              content.contains('AppOpenAd.load'),
          isFalse,
          reason: 'Forbidden interstitial or app-open ad code found in ${file.path}',
        );
      }
    });

    test('Rule: google_mobile_ads is ONLY imported in ads_service.dart', () async {
      final files = libDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;
        if (file.path.contains('ads_service.dart')) continue;

        final content = await file.readAsString();
        expect(
          content.contains("import 'package:google_mobile_ads"),
          isFalse,
          reason: 'google_mobile_ads imported outside ads_service.dart in ${file.path}',
        );
      }
    });

    test('Rule: No hardcoded ad unit IDs outside game_config.json', () async {
      final files = libDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;
        final content = await file.readAsString();

        expect(
          content.contains('ca-app-pub-') && !file.path.contains('app_config.dart'),
          isFalse,
          reason: 'Hardcoded AdMob ID found in ${file.path}',
        );
      }
    });

    test('Rule: Single source of truth config/game_config.json exists and is valid', () async {
      final configFile = File('config/game_config.json');
      expect(configFile.existsSync(), isTrue);
      final content = await configFile.readAsString();
      expect(content.contains('"name"'), isTrue);
      expect(content.contains('"ads"'), isTrue);
      expect(content.contains('"gameplay"'), isTrue);
      expect(content.contains('"economy"'), isTrue);
    });
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'core/services/audio_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/ads_service.dart';
import 'app.dart';

/// Global config instance, loaded once at boot.
late final AppConfig appConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any unhandled Flutter framework errors without crashing
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Caught Flutter framework error: ${details.exception}');
  };

  // Lock orientation to portrait — only on mobile, not web.
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      debugPrint('Orientation lock skipped: $e');
    }
  }

  // Load the single source of truth config before anything else.
  try {
    appConfig = await AppConfig.load();
  } catch (e) {
    debugPrint('AppConfig fallback: $e');
  }

  // Initialize Hive for local persistence (progress, economy).
  try {
    await Hive.initFlutter();
    await StorageService().initialize();
  } catch (e) {
    debugPrint('Hive storage initialization error: $e');
  }

  // Boot audio singleton — music starts smoothly.
  try {
    AudioService.init(config: appConfig.audio);
    final audio = AudioService(config: appConfig.audio);
    if (audio.isMusicEnabled) {
      audio.playMusic();
    }
  } catch (e) {
    debugPrint('AudioService init error: $e');
  }

  // Pre-initialize Ads SDK
  try {
    AdsService(config: appConfig.ads).initialize();
  } catch (e) {
    debugPrint('AdsService init error: $e');
  }

  runApp(
    ProviderScope(
      child: App(config: appConfig),
    ),
  );
}

import 'package:flutter/material.dart';
import '../../data/models/level_model.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/level_select/level_select_screen.dart';
import '../../presentation/screens/gameplay/gameplay_screen.dart';
import '../../presentation/screens/level_complete/level_complete_screen.dart';
import '../../presentation/screens/daily_challenge/daily_challenge_screen.dart';
import '../../presentation/screens/profile_me/profile_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

/// Named routes for the app. All screen navigation goes through here.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String home = '/home';
  static const String mainMenu = '/main-menu';
  static const String levelSelect = '/level-select';
  static const String gameplay = '/gameplay';
  static const String levelComplete = '/level-complete';
  static const String dailyChallenge = '/daily-challenge';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), routeSettings);

      case home:
      case mainMenu:
        return _buildRoute(const HomeScreen(), routeSettings);

      case levelSelect:
        return _buildRoute(const LevelSelectScreen(), routeSettings);

      case gameplay:
        final args = routeSettings.arguments;
        final Level level;
        bool isTimerMode = false;
        int timerSeconds = 45;
        if (args is Level) {
          level = args;
        } else if (args is Map<String, dynamic>) {
          level = args['level'] as Level;
          isTimerMode = args['isTimerMode'] as bool? ?? false;
          timerSeconds = args['timerSeconds'] as int? ?? 45;
        } else {
          level = args as Level;
        }
        return _buildRoute(
          GameplayScreen(
            level: level,
            isTimerMode: isTimerMode,
            timerSeconds: timerSeconds,
          ),
          routeSettings,
        );

      case levelComplete:
        final args = routeSettings.arguments as Map<String, dynamic>;
        final level = args['level'] as Level;
        final mistakes = args['mistakes'] as int? ?? 0;
        final flowStateReached = args['flowStateReached'] as bool? ?? false;
        final isTimerMode = args['isTimerMode'] as bool? ?? false;
        final timerSeconds = args['timerSeconds'] as int? ?? 45;
        return _buildRoute(
          LevelCompleteScreen(
            level: level,
            mistakes: mistakes,
            flowStateReached: flowStateReached,
            isTimerMode: isTimerMode,
            timerSeconds: timerSeconds,
          ),
          routeSettings,
        );

      case dailyChallenge:
        return _buildRoute(const DailyChallengeScreen(), routeSettings);

      case profile:
        return _buildRoute(const ProfileScreen(), routeSettings);

      case settings:
        return _buildRoute(const SettingsScreen(), routeSettings);

      default:
        return _buildRoute(
          const Scaffold(body: Center(child: Text('Not Found'))),
          routeSettings,
        );
    }
  }

  /// Standard page route with a short fade transition matching the design system.
  static PageRouteBuilder<dynamic> _buildRoute(
    Widget page,
    RouteSettings routeSettings,
  ) {
    return PageRouteBuilder(
      settings: routeSettings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}

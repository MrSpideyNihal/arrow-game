import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

/// Root application widget. Theming and routing are driven entirely by AppConfig.
class App extends StatelessWidget {
  final AppConfig config;

  const App({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final themeMode = switch (config.theme.defaultMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: config.app.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(config.theme),
      darkTheme: AppTheme.dark(config.theme),
      themeMode: themeMode,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

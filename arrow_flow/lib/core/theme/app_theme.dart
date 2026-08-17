import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Parses a hex color string (e.g. "#EDEEF2") into a Flutter Color.
Color _hexColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('FF');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Builds the soft-neumorphism theme from config colors.
/// Light warm-gray backgrounds, dual soft shadows, clean geometric typography.
class AppTheme {
  AppTheme._();

  /// Neumorphic shadow pair: light highlight (top-left) and dark shadow (bottom-right).
  static List<BoxShadow> neumorphicShadows(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const [
        BoxShadow(
          color: Color(0xFFFFFFFF),
          offset: Offset(-4, -4),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Color(0xFFBEC3CF),
          offset: Offset(4, 4),
          blurRadius: 8,
        ),
      ];
    } else {
      return const [
        BoxShadow(
          color: Color(0xFF1E2028),
          offset: Offset(-4, -4),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Color(0xFF0A0B0E),
          offset: Offset(4, 4),
          blurRadius: 8,
        ),
      ];
    }
  }

  static ThemeData light(ThemeConfig config) {
    final colors = config.light;
    final bg = _hexColor(colors.background);
    final surface = _hexColor(colors.surface);
    final accent = _hexColor(colors.accent);
    final textPrimary = _hexColor(colors.textPrimary);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(textPrimary),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: textPrimary),
      useMaterial3: true,
    );
  }

  static ThemeData dark(ThemeConfig config) {
    final colors = config.dark;
    final bg = _hexColor(colors.background);
    final surface = _hexColor(colors.surface);
    final accent = _hexColor(colors.accent);
    final textPrimary = _hexColor(colors.textPrimary);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(textPrimary),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: textPrimary),
      useMaterial3: true,
    );
  }

  /// Clean geometric sans typography. Two weights only: regular (400) and semibold (600).
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor.withValues(alpha: 0.7),
      ),
    );
  }
}

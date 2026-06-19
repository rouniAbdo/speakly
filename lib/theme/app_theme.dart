import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised colours and theme for the app.
///
/// The look is intentionally playful & gamified (think Duolingo): a rounded
/// friendly font, bold candy colours, big rounded corners and soft shadows.
class AppTheme {
  static const Color seed = Color(0xFF7C3AED); // vibrant violet
  static const Color accent = Color(0xFF06B6D4); // cyan
  static const Color streak = Color(0xFFFF7A00); // fiery orange (streak flame)
  static const Color gold = Color(0xFFFFB100); // trophy gold

  /// A bright, cheerful palette used to colour cards, chips and words.
  static const List<Color> palette = [
    Color(0xFFFF5A5F), // coral red
    Color(0xFFFF8A3D), // orange
    Color(0xFFFFC23D), // amber
    Color(0xFF4ADE80), // green
    Color(0xFF2DD4BF), // teal
    Color(0xFF38BDF8), // sky
    Color(0xFF6366F1), // indigo
    Color(0xFFA855F7), // violet
    Color(0xFFF472B6), // pink
    Color(0xFFE879F9), // fuchsia
  ];

  /// Stable colour for a category name.
  static Color categoryColor(String name) =>
      palette[name.hashCode.abs() % palette.length];

  /// Stable colour for a single word.
  static Color wordColor(String word) =>
      palette[word.toLowerCase().hashCode.abs() % palette.length];

  /// Two stable, harmonious colours for a gradient keyed off a string.
  static List<Color> gradientFor(String key) {
    final i = key.hashCode.abs() % palette.length;
    return [palette[i], palette[(i + 3) % palette.length]];
  }

  /// A soft, friendly drop shadow for raised cards.
  static List<BoxShadow> softShadow(Color tint, {double opacity = 0.18}) => [
        BoxShadow(
          color: tint.withValues(alpha: opacity),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(surface: const Color(0xFFFBF7FF));
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = GoogleFonts.nunitoTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.nunito(
          color: scheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        indicatorColor: seed.withValues(alpha: 0.16),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? seed : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? seed : scheme.onSurfaceVariant,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: seed,
        indicatorColor: seed,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Colour used to represent a difficulty level.
  static Color levelColor(String level, ColorScheme scheme) {
    switch (level) {
      case 'Beginner':
        return const Color(0xFF22C55E);
      case 'Intermediate':
        return const Color(0xFFF59E0B);
      case 'Advanced':
        return const Color(0xFFEF4444);
      default:
        return scheme.primary;
    }
  }

  /// A small emoji that fits a difficulty level — adds a playful touch.
  static String levelEmoji(String level) {
    switch (level) {
      case 'Beginner':
        return '🌱';
      case 'Intermediate':
        return '⚡';
      case 'Advanced':
        return '🔥';
      default:
        return '✨';
    }
  }
}

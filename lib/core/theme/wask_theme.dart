import 'package:flutter/material.dart';

class WaskColors {
  static const Color background = Color(0xFF000000);
  static const Color canvas = Color(0xFF07090E);
  static const Color surface = Color(0xFF12151C);
  static const Color surfaceElevated = Color(0xFF1A1F29);
  static const Color border = Color(0x1EFFFFFF);
  static const Color electricBlue = Color(0xFF007BFF);
  static const Color energyOrange = Color(0xFFFF5733);
  static const Color emerald = Color(0xFF10B981);
  static const Color iceBlue = Color(0xFF38BDF8);
  static const Color yapePurple = Color(0xFF742284);
  static const Color yapeLavender = Color(0xFFC084FC);
  static const Color plinCyan = Color(0xFF06B6D4);
  static const Color amber = Color(0xFFF59E0B);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB3B8C4);
}

class WaskTheme {
  static const TextStyle tabularNumberStyle = TextStyle(
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: WaskColors.background,
      primaryColor: WaskColors.electricBlue,
      colorScheme: const ColorScheme.dark(
        primary: WaskColors.electricBlue,
        secondary: WaskColors.energyOrange,
        surface: WaskColors.surface,
        error: WaskColors.energyOrange,
        onPrimary: WaskColors.primaryText,
        onSurface: WaskColors.primaryText,
      ),
      cardColor: WaskColors.surface,
      dividerColor: WaskColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: WaskColors.background,
        foregroundColor: WaskColors.primaryText,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: const Color(0xFF0D1017),
        indicatorColor: WaskColors.electricBlue.withOpacity(0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 20,
            color: isSelected
                ? WaskColors.electricBlue
                : WaskColors.secondaryText,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            height: 1.1,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? WaskColors.primaryText
                : WaskColors.secondaryText,
          );
        }),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: WaskColors.primaryText,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: WaskColors.secondaryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WaskColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WaskColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: WaskColors.electricBlue, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WaskColors.primaryText,
          side: const BorderSide(color: Color(0x30FFFFFF)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WaskColors.electricBlue,
          foregroundColor: WaskColors.primaryText,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WaskColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: WaskColors.primaryText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

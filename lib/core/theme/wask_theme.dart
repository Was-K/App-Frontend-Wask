import 'package:flutter/material.dart';

class WaskColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color electricBlue = Color(0xFF007BFF);
  static const Color energyOrange = Color(0xFFFF5733);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB3B3B3);
}

class WaskTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: WaskColors.background,
      primaryColor: WaskColors.electricBlue,
      colorScheme: const ColorScheme.dark(
        primary: WaskColors.electricBlue,
        surface: WaskColors.surface,
        error: WaskColors.energyOrange,
        onPrimary: WaskColors.primaryText,
        onSurface: WaskColors.primaryText,
      ),
      cardColor: WaskColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: WaskColors.background,
        foregroundColor: WaskColors.primaryText,
        centerTitle: false,
        elevation: 0,
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
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
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
    );
  }
}

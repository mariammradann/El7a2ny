import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandRed = Color(0xFFE61717);
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color lightBg = Color(0xFFF5F3EF); // Matching emergencyPageBg
  static const Color lightSurface = Colors.white;
  static const Color secondaryTeal = Color(0xFF1A5F6B);
  static const Color premiumGold = Color(0xFFFDC800);
  static const Color premiumGoldDark = Color(0xFFE95F32);
  static const Color premiumNavy = Color(0xFF0F172A);
  static const Color premiumSurface = Color(0xFF1E293B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'NotoSansArabic',
      scaffoldBackgroundColor: lightBg,
      primaryColor: brandRed,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandRed,
        brightness: Brightness.light,
        primary: brandRed,
        error: brandRed,
        surface: lightSurface,
        onSurface: const Color(0xFF2C2C2C), // Matching emergencyTextDark
        surfaceContainerHighest: const Color(0xFFEAE7E2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black87),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: brandRed,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: 'NotoSansArabic',
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'NotoSansArabic',
      scaffoldBackgroundColor: darkBg,
      primaryColor: brandRed,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandRed,
        brightness: Brightness.dark,
        primary: brandRed,
        error: brandRed,
        surface: darkSurface,
        onSurface: const Color(0xFFE2E8F0),
        surfaceContainerHighest: const Color(0xFF334155),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: brandRed,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: 'NotoSansArabic',
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }

  static ThemeData get premiumTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'NotoSansArabic',
      scaffoldBackgroundColor: const Color(0xFFFFFBF0),
      primaryColor: const Color(0xFFF59E0B),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF59E0B),
        brightness: Brightness.light,
        primary: const Color(0xFFF59E0B),
        secondary: const Color(0xFFE95F32),
        secondaryContainer: const Color(0xFFFDC800),
        surface: Colors.white,
        onSurface: const Color(0xFF1E293B),
        surfaceContainerHighest: const Color(0xFFF1F5F9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFFF59E0B),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: 'NotoSansArabic',
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1E293B)),
        bodyMedium: TextStyle(color: Color(0xFF475569)),
        titleLarge: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}


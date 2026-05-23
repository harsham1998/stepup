import 'package:flutter/material.dart';

class AppTheme {
  static const _primary    = Color(0xFF6366F1);
  static const _secondary  = Color(0xFF8B5CF6);
  static const _background = Color(0xFF0C0C18);
  static const _surface    = Color(0xFF13131F);
  static const _cardBorder = Color(0xFF1A1A2E);
  static const _green      = Color(0xFF34D399);
  static const _amber      = Color(0xFFFBBF24);
  static const _pink       = Color(0xFFF472B6);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _background,
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _cardBorder, width: 1),
      ),
      elevation: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: const TextTheme(
      displaySmall:  TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      titleMedium:   TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      bodyMedium:    TextStyle(color: Color(0xFF9CA3AF)),
      bodySmall:     TextStyle(color: Color(0xFF4B5563), fontSize: 11),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF08080F),
      selectedItemColor: _primary,
      unselectedItemColor: Color(0xFF374151),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0D0D1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1F2937)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1F2937)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    ),
  );

  // Convenience colour accessors
  static const green = _green;
  static const amber = _amber;
  static const pink  = _pink;
  static const primary = _primary;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const voltLime  = Color(0xFFD4FF3A);
  static const amber     = Color(0xFFFFB547);
  static const bg        = Color(0xFF050510);
  static const surface   = Color(0xFF0D0D1A);
  static const surface2  = Color(0xFF13131F);
  static const ink2      = Color(0xFFA3A3B3);
  static const ink3      = Color(0xFF4B5563);
  static const border    = Color(0x14FFFFFF);
  static const border2   = Color(0x1EFFFFFF);
  static const surface3  = Color(0xFF18182A);
  static const red       = Color(0xFFEF4444);

  // Legacy aliases kept so existing screens don't break
  static const primary   = voltLime;
  static const secondary = amber;
  static const green     = Color(0xFF34D399);
  static const pink      = Color(0xFFF472B6);
  static const purple    = Color(0xFFA78BFA);
  static const blue      = Color(0xFF63B4FF);

  static TextStyle bigNum(double size, {Color color = Colors.white}) =>
      GoogleFonts.bigShouldersDisplay(fontSize: size, fontWeight: FontWeight.w900, color: color);

  static TextStyle label(double size, {Color color = const Color(0xFFA3A3B3)}) =>
      GoogleFonts.inter(fontSize: size, color: color);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: voltLime,
      secondary: amber,
      surface: surface,
      onPrimary: Color(0xFF050510),
      onSecondary: Color(0xFF050510),
      onSurface: Colors.white,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displaySmall:  GoogleFonts.bigShouldersDisplay(color: Colors.white, fontWeight: FontWeight.w900),
      headlineLarge: GoogleFonts.bigShouldersDisplay(color: Colors.white, fontWeight: FontWeight.w900),
      headlineMedium:GoogleFonts.bigShouldersDisplay(color: Colors.white, fontWeight: FontWeight.w800),
      headlineSmall: GoogleFonts.bigShouldersDisplay(color: Colors.white, fontWeight: FontWeight.w700),
      titleLarge:    GoogleFonts.bigShouldersDisplay(color: Colors.white, fontWeight: FontWeight.w700),
      titleMedium:   GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
      bodyLarge:     GoogleFonts.inter(color: Colors.white),
      bodyMedium:    GoogleFonts.inter(color: Color(0xFFA3A3B3)),
      bodySmall:     GoogleFonts.inter(color: Color(0xFF4B5563), fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: border),
      ),
      elevation: 0,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.bigShouldersDisplay(
        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: voltLime,
        foregroundColor: const Color(0xFF050510),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        textStyle: GoogleFonts.bigShouldersDisplay(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: voltLime,
      unselectedItemColor: const Color(0xFF4B5563),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.bigShouldersDisplay(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.bigShouldersDisplay(fontSize: 11),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: voltLime, width: 1.5)),
      labelStyle: const TextStyle(color: Color(0xFF4B5563)),
      hintStyle: const TextStyle(color: Color(0xFF4B5563)),
    ),
  );
}

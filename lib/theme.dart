import 'package:flutter/material.dart';

class FT {
  static const purple = Color(0xFF6C4CF1);
  static const pink = Color(0xFFFF4F8B);
  static const yellow = Color(0xFFFFC93C);
  static const mint = Color(0xFF22C7A9);
  static const cream = Color(0xFFFFF8EC);
  static const ink = Color(0xFF2B2250);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: FT.purple,
    primary: FT.purple,
    secondary: FT.pink,
    tertiary: FT.mint,
    surface: FT.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FT.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: FT.cream,
      foregroundColor: FT.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: ThemeData.light().textTheme.apply(
          bodyColor: FT.ink,
          displayColor: FT.ink,
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: FT.purple, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

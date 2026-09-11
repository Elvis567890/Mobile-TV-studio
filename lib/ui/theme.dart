import 'package:flutter/material.dart';

/// Dark, high-contrast theme built for live use in the field.
ThemeData buildStudioTheme() {
  const bg = Color(0xFF0B0B0F);
  const surface = Color(0xFF14141A);
  const accent = Color(0xFF3B82F6);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    primaryColor: accent,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: Color(0xFF8B5CF6),
      surface: surface,
      error: Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}

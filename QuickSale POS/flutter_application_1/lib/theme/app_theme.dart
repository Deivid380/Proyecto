import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Paleta de colores POS Profesional
  static final Color _primaryColor = Colors.blueGrey[700]!;
  static const Color _secondaryColor = Colors.blueGrey;
  static const Color _lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color _darkBackgroundColor = Color(0xFF121212);
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _darkSurfaceColor = Color(0xFF1E1E1E);

  // --- Tema Claro ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    primarySwatch: Colors.blueGrey,
    scaffoldBackgroundColor: _lightBackgroundColor,
    fontFamily: GoogleFonts.roboto().fontFamily,
    appBarTheme: AppBarTheme(
      elevation: 1,
      backgroundColor: _lightSurfaceColor,
      foregroundColor: Colors.black87,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: _lightSurfaceColor,
      background: _lightBackgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      bodyLarge: const TextStyle(fontSize: 18.0),
      bodyMedium: const TextStyle(fontSize: 16.0),
      labelLarge: const TextStyle(fontSize: 18.0), // For buttons
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 64), // Botones más grandes
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    ),
  );

  // --- Tema Oscuro ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _darkBackgroundColor,
    fontFamily: GoogleFonts.roboto().fontFamily,
    appBarTheme: AppBarTheme(
      elevation: 1,
      backgroundColor: _darkSurfaceColor,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: _darkSurfaceColor,
      background: _darkBackgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: const TextStyle(fontSize: 18.0),
      bodyMedium: const TextStyle(fontSize: 16.0),
      labelLarge: const TextStyle(fontSize: 18.0), // For buttons
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 64), // Botones más grandes
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    ),
  );
}

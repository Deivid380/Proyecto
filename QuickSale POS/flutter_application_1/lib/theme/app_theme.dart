import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Nueva paleta de colores: Vibrante, Limpia y Profesional
  static const Color primaryColor = Color(0xFF3498DB); // Un azul más brillante y moderno
  static const Color secondaryColor = Color(0xFF5DADE2); // Un azul claro para acentos
  static const Color accentColor = Color(0xFFF39C12); // Naranja para llamadas a la acción
  static const Color backgroundColor = Color(0xFFFDFEFE); // Fondo casi blanco, muy limpio
  static const Color surfaceColor = Colors.white; // Blanco puro para tarjetas
  static const Color textColor = Color(0xFF2C3E50); // Un gris oscuro azulado para texto
  static const Color errorColor = Color(0xFFE74C3C);

  // Colores para el Tema Oscuro
  static const Color primaryColorDark = Color(0xFF5DADE2);
  static const Color backgroundColorDark = Color(0xFF1B2631);
  static const Color surfaceColorDark = Color(0xFF283747);
  static const Color textColorDark = Color(0xFFFDFEFE);

  // Tipografía moderna y legible: Poppins
  static final TextTheme _lightTextTheme = GoogleFonts.poppinsTextTheme().copyWith(
    displayLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
    displayMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
    headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
    titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
    bodyLarge: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.9)),
    bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.8)),
    labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
  );

  static final TextTheme _darkTextTheme = GoogleFonts.poppinsTextTheme().copyWith(
    displayLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: textColorDark),
    displayMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColorDark),
    headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColorDark),
    titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColorDark),
    bodyLarge: GoogleFonts.poppins(fontSize: 16, color: textColorDark.withOpacity(0.9)),
    bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textColorDark.withOpacity(0.8)),
    labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
  );

  // --- TEMA CLARO ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Poppins',
    iconTheme: const IconThemeData(color: textColor, size: 24.0),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent, // Fondo transparente para que el gradiente se vea
      foregroundColor: textColor,
      iconTheme: const IconThemeData(color: primaryColor, size: 28.0),
      titleTextStyle: _lightTextTheme.headlineSmall,
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
    ),
    textTheme: _lightTextTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(60, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.2),
        textStyle: _lightTextTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      hintStyle: _lightTextTheme.bodyMedium?.copyWith(color: textColor.withOpacity(0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // Sin bordes para un look más limpio
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor.withOpacity(0.85), // Transparencia para integrar con el fondo
      selectedItemColor: primaryColor,
      unselectedItemColor: textColor.withOpacity(0.5),
      elevation: 0, // Sin sombra
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: _lightTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: _lightTextTheme.bodyMedium,
    ),
  );

  // --- TEMA OSCURO ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColorDark,
    scaffoldBackgroundColor: backgroundColorDark,
    fontFamily: 'Poppins',
    iconTheme: const IconThemeData(color: textColorDark, size: 24.0),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent, // Fondo transparente
      foregroundColor: textColorDark,
      iconTheme: const IconThemeData(color: primaryColorDark, size: 28.0),
      titleTextStyle: _darkTextTheme.headlineSmall,
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryColorDark,
      secondary: secondaryColor,
      surface: surfaceColorDark,
      error: errorColor,
      onPrimary: textColor,
      onSecondary: textColor,
      onSurface: textColorDark,
      onError: Colors.white,
    ),
    textTheme: _darkTextTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorDark,
        foregroundColor: textColor,
        minimumSize: const Size(60, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 2,
        shadowColor: primaryColorDark.withOpacity(0.2),
        textStyle: _darkTextTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColorDark,
      hintStyle: _darkTextTheme.bodyMedium?.copyWith(color: textColorDark.withOpacity(0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColorDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColorDark.withOpacity(0.85),
      selectedItemColor: primaryColorDark,
      unselectedItemColor: textColorDark.withOpacity(0.6),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: _darkTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: _darkTextTheme.bodyMedium,
    ),
  );

  // Widget de fondo con gradiente para un toque extra
  static Widget gradientBackground({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.05),
            backgroundColor,
            backgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: child,
    );
  }
  
  // Gradiente para el tema oscuro
  static Widget gradientBackgroundDark({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColorDark.withOpacity(0.1),
            backgroundColorDark,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4],
        ),
      ),
      child: child,
    );
  }
}

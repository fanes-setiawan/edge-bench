import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EdgeTheme {
  // PRD Color Tokens
  static const Color surfaceBase = Color(0xFF0B1220);
  static const Color surfaceRaised = Color(0xFF141C2E);
  static const Color surfaceOverlay = Color(0xFF1C2740);
  
  static const Color accentAction = Color(0xFFF97316);
  
  static const Color stateGood = Color(0xFF34D399);
  static const Color stateWarn = Color(0xFFFBBF24);
  static const Color stateFail = Color(0xFFF87171);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceBase,
      colorScheme: const ColorScheme.dark(
        surface: surfaceBase,
        primary: accentAction,
        error: stateFail,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardColor: surfaceRaised,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceRaised,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // Wajib digunakan untuk semua telemetri numerik sesuai PRD
  static TextStyle get monoTextStyle {
    return GoogleFonts.jetBrainsMono(
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
  }
}

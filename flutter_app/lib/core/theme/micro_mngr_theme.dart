import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MicroMngrTheme {
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF1C1B1B);
  static const Color surfaceHighest = Color(0xFF353438);
  static const Color primary = Color(0xFF64FFDA);
  static const Color onPrimary = Color(0xFF000000);
  static const Color onBackground = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFCF6679);
  static const Color border = Color(0xFF4F4F4F);

  // Material 3 design colors
  static const Color primaryFixedDim = Color(0xFF38DEBB);
  static const Color outlineVariant = Color(0xFF3C4A45);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color tertiaryFixedDim = Color(0xFFDEC65A);
  static const Color onSurfaceVariant = Color(0xFFBACACB);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      // Enable font antialiasing
      fontFamily: GoogleFonts.spaceMonoTextTheme().bodyMedium?.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        secondary: primary,
        surface: surface,
        onSurface: onBackground,
        error: error,
        outline: border,
        surfaceBright: surfaceHighest,
      ),

      // Monospace Typography - "Space Mono"
      textTheme:
          GoogleFonts.spaceMonoTextTheme(
            ThemeData.dark().textTheme,
          ).apply(
            bodyColor: onBackground,
            displayColor: primary,
          ),

      // AppBar - Technical & Flat
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: primary),
        shape: Border(
          bottom: BorderSide(color: border, width: 1),
        ),
      ),

      // Buttons - Sharp edges, bold accents
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // Input Decoration - Terminal style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        labelStyle: const TextStyle(color: primary),
        hintStyle: TextStyle(color: onBackground.withValues(alpha: 0.5)),
      ),

      // Cards - Subtle outlines
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: primary.withValues(alpha: 0.1),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return IconThemeData(color: onBackground.withValues(alpha: 0.6));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primary, fontWeight: FontWeight.bold);
          }
          return TextStyle(color: onBackground.withValues(alpha: 0.6));
        }),
      ),
    );
  }
}

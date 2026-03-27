import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const bg = Color(0xFF0D0F14);
  static const bg2 = Color(0xFF141720);
  static const bg3 = Color(0xFF1C2030);
  static const bg4 = Color(0xFF232840);

  // Accents
  static const teal = Color(0xFF00E5B0);
  static const teal2 = Color(0xFF00B88A);
  static const coral = Color(0xFFFF6B6B);
  static const amber = Color(0xFFFFC145);
  static const purple = Color(0xFFA78BFA);
  static const blue = Color(0xFF60A5FA);

  // Text
  static const text = Color(0xFFF0F2FF);
  static const text2 = Color(0xFF8B92B8);
  static const text3 = Color(0xFF555E7A);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.teal,
          surface: AppColors.bg2,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(
          const TextTheme(
            bodyLarge: TextStyle(color: AppColors.text),
            bodyMedium: TextStyle(color: AppColors.text),
            bodySmall: TextStyle(color: AppColors.text2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bg3,
          hintStyle: const TextStyle(color: AppColors.text3, fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.bg4, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.bg4, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.teal, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        useMaterial3: true,
      );
}

// Text style helpers
TextStyle syneStyle({
  double size = 14,
  FontWeight weight = FontWeight.w700,
  Color color = AppColors.text,
}) =>
    GoogleFonts.syne(fontSize: size, fontWeight: weight, color: color);

TextStyle dmStyle({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.text,
}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);

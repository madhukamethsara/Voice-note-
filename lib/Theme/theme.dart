import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  final Color bg;
  final Color bg2;
  final Color bg3;
  final Color bg4;

  final Color teal;
  final Color coral;
  final Color amber;
  final Color purple;
  final Color blue;

  final Color text;
  final Color text2;
  final Color text3;

  final Color white;
  final Color black;

  const AppColors({
    required this.bg,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.teal,
    required this.coral,
    required this.amber,
    required this.purple,
    required this.blue,
    required this.text,
    required this.text2,
    required this.text3,
    required this.white,
    required this.black,
  });

  static const dark = AppColors(
    bg: Color(0xFF0D0F14),
    bg2: Color(0xFF141720),
    bg3: Color(0xFF1C2030),
    bg4: Color(0xFF232840),
    teal: Color(0xFF00E5B0),
    coral: Color(0xFFFF6B6B),
    amber: Color(0xFFFFC145),
    purple: Color(0xFFA78BFA),
    blue: Color(0xFF60A5FA),
    text: Color(0xFFF0F2FF),
    text2: Color(0xFF8B92B8),
    text3: Color(0xFF555E7A),
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
  );

  static const light = AppColors(
    bg: Color(0xFFF7F9FC),
    bg2: Color(0xFFFFFFFF),
    bg3: Color(0xFFF1F5F9),
    bg4: Color(0xFFD8E0EA),
    teal: Color(0xFF00B88A),
    coral: Color(0xFFE85D5D),
    amber: Color(0xFFE6A700),
    purple: Color(0xFF8B6EF3),
    blue: Color(0xFF4F8CFF),
    text: Color(0xFF0F172A),
    text2: Color(0xFF475569),
    text3: Color(0xFF64748B),
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
  );
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.dark.bg,
    primaryColor: AppColors.dark.teal,
    colorScheme: ColorScheme.dark(
      primary: AppColors.dark.teal,
      secondary: AppColors.dark.amber,
      surface: AppColors.dark.bg2,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.dark.bg,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.dark.text),
      titleTextStyle: GoogleFonts.syne(
        color: AppColors.dark.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: GoogleFonts.dmSansTextTheme().apply(
      bodyColor: AppColors.dark.text,
      displayColor: AppColors.dark.text,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.dark.bg2,
      contentTextStyle: GoogleFonts.dmSans(
        color: AppColors.dark.text,
        fontSize: 13,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.light.bg,
    primaryColor: AppColors.light.teal,
    colorScheme: ColorScheme.light(
      primary: AppColors.light.teal,
      secondary: AppColors.light.amber,
      surface: AppColors.light.bg2,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.light.bg,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.light.text),
      titleTextStyle: GoogleFonts.syne(
        color: AppColors.light.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: GoogleFonts.dmSansTextTheme().apply(
      bodyColor: AppColors.light.text,
      displayColor: AppColors.light.text,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.light.bg2,
      contentTextStyle: GoogleFonts.dmSans(
        color: AppColors.light.text,
        fontSize: 13,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
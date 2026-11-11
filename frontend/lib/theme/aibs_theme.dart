import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

abstract final class AibsColors {
  static const primary = Color(0xFF2F6FED);
  static const primaryStrong = Color(0xFF1F55C8);
  static const sky = Color(0xFF78AAFF);
  static const primarySoft = Color(0xFFE8F0FE);
  static const surface = Color(0xFFF5F8FF);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF14233F);
  static const inkMuted = Color(0xFF5B6A85);
  static const line = Color(0xFFE1E8F4);
  static const ok = Color(0xFF22A06B);
  static const okInk = Color(0xFF11774A);
  static const okSoft = Color(0xFFE3F6EC);
  static const warn = Color(0xFFF5A524);
  static const warnInk = Color(0xFF8A5300);
  static const warnSoft = Color(0xFFFFF3DC);
  static const bad = Color(0xFFE5534B);
  static const badInk = Color(0xFFB02B24);
  static const badSoft = Color(0xFFFDE8E6);
  static const unknown = Color(0xFF9AA5B8);
  static const unknownSoft = Color(0xFFEEF1F6);
}

abstract final class AibsTheme {
  static ThemeData get light {
    final base = google_fonts.GoogleFonts.nunitoTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AibsColors.primary,
        primary: AibsColors.primary,
        surface: AibsColors.surface,
        error: AibsColors.bad,
      ),
      scaffoldBackgroundColor: AibsColors.surface,
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          color: AibsColors.ink,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          color: AibsColors.ink,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        titleLarge: base.titleLarge?.copyWith(
          color: AibsColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          color: AibsColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          color: AibsColors.inkMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AibsColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: const TextStyle(color: AibsColors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AibsColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AibsColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AibsColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AibsColors.card,
        indicatorColor: AibsColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AibsColors.primaryStrong
                : AibsColors.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

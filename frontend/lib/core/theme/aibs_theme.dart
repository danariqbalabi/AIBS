// AIBS ThemeData built from AibsTokens.
//
// Use it in MaterialApp:  theme: AibsTheme.light,

import 'package:flutter/material.dart';

import 'aibs_tokens.dart';

abstract final class AibsTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AibsColors.primary,
      onPrimary: AibsColors.onPrimary,
      primaryContainer: AibsColors.primarySoft,
      onPrimaryContainer: AibsColors.primaryStrong,
      secondary: AibsColors.primaryStrong,
      onSecondary: AibsColors.onPrimary,
      error: AibsColors.bad,
      onError: AibsColors.onPrimary,
      errorContainer: AibsColors.badSoft,
      onErrorContainer: AibsColors.badInk,
      surface: AibsColors.surface,
      onSurface: AibsColors.ink,
      onSurfaceVariant: AibsColors.inkMuted,
      outline: AibsColors.line,
      outlineVariant: AibsColors.line,
      scrim: AibsColors.scrim,
      surfaceContainerLowest: AibsColors.card,
      surfaceContainerLow: AibsColors.card,
      surfaceContainer: AibsColors.card,
      surfaceContainerHigh: AibsColors.card,
      surfaceContainerHighest: AibsColors.unknownSoft,
    );

    final text = TextTheme(
      displayLarge: AibsType.display,
      headlineLarge: AibsType.title,
      headlineMedium: AibsType.titleDetail,
      headlineSmall: AibsType.sheetTitle,
      titleLarge: AibsType.verdict,
      titleMedium: AibsType.option,
      titleSmall: AibsType.sectionTitle,
      bodyLarge: AibsType.bodyStrong,
      bodyMedium: AibsType.body,
      bodySmall: AibsType.caption,
      labelLarge: AibsType.button,
      labelMedium: AibsType.label,
      labelSmall: AibsType.micro,
    );

    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AibsRadius.bubble),
      borderSide: BorderSide(color: c, width: 2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AibsType.family,
      textTheme: text,
      scaffoldBackgroundColor: AibsColors.surface,
      splashFactory:
          NoSplash.splashFactory, // feedback = press scale, not ripples
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AibsColors.ink,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AibsColors.card,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AibsColors.card,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AibsColors.scrim,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AibsColors.line,
        dragHandleSize: Size(40, 5),
        shape: RoundedRectangleBorder(borderRadius: AibsRadius.sheetTop),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AibsColors.card,
        surfaceTintColor: Colors.transparent,
        barrierColor: AibsColors.scrim,
        insetPadding: EdgeInsets.symmetric(horizontal: AibsSpace.s24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AibsRadius.xxl)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AibsColors.card,
        hintStyle: AibsType.option.copyWith(color: AibsColors.inkMuted),
        labelStyle: AibsType.caption,
        constraints: const BoxConstraints(minHeight: AibsSize.input),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        border: border(AibsColors.line),
        enabledBorder: border(AibsColors.line),
        focusedBorder: border(AibsColors.primary),
        errorBorder: border(AibsColors.bad),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AibsColors.card),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AibsColors.primary
              : AibsColors.trackOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}

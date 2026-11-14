// AIBS ThemeData built from AibsTokens.
//
// Use it in MaterialApp:  theme: AibsTheme.light,

import 'package:flutter/material.dart';

import 'aibs_tokens.dart';

abstract final class AibsTheme {
  static ThemeData get dark {
    final base = light;
    final scheme = base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: AibsDarkColors.primary,
      onPrimary: AibsDarkColors.surface,
      primaryContainer: AibsDarkColors.primarySoft,
      onPrimaryContainer: AibsDarkColors.primaryStrong,
      secondary: AibsDarkColors.primaryStrong,
      surface: AibsDarkColors.surface,
      onSurface: AibsDarkColors.ink,
      onSurfaceVariant: AibsDarkColors.inkMuted,
      outline: AibsDarkColors.line,
      outlineVariant: AibsDarkColors.line,
      error: AibsDarkColors.badInk,
      errorContainer: AibsDarkColors.badSoft,
      onErrorContainer: AibsDarkColors.badInk,
      surfaceContainerLowest: AibsDarkColors.card,
      surfaceContainerLow: AibsDarkColors.card,
      surfaceContainer: AibsDarkColors.card,
      surfaceContainerHigh: AibsDarkColors.card,
      surfaceContainerHighest: AibsDarkColors.unknownSoft,
      scrim: AibsDarkColors.scrim,
    );
    return base.copyWith(
      colorScheme: scheme,
      textTheme: base.textTheme.apply(
        bodyColor: AibsDarkColors.ink,
        displayColor: AibsDarkColors.ink,
      ),
      scaffoldBackgroundColor: AibsDarkColors.surface,
      iconTheme: const IconThemeData(color: AibsDarkColors.inkMuted),
      dividerColor: AibsDarkColors.line,
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: AibsDarkColors.ink,
      ),
      cardTheme: base.cardTheme.copyWith(color: AibsDarkColors.card),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: AibsDarkColors.card,
        dragHandleColor: AibsDarkColors.line,
        modalBarrierColor: AibsDarkColors.scrim,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: AibsDarkColors.card,
        barrierColor: AibsDarkColors.scrim,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: AibsDarkColors.card,
        hintStyle: AibsType.option.copyWith(color: AibsDarkColors.inkMuted),
        labelStyle: AibsType.caption.copyWith(color: AibsDarkColors.inkMuted),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AibsRadius.bubble)),
          borderSide: BorderSide(color: AibsDarkColors.line, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AibsRadius.bubble)),
          borderSide: BorderSide(color: AibsDarkColors.line, width: 2),
        ),
      ),
      switchTheme: base.switchTheme.copyWith(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AibsColors.primary
              : AibsDarkColors.trackOff,
        ),
      ),
    );
  }

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

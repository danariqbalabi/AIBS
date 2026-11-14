import 'package:aibs_app/core/theme/aibs_theme.dart';
import 'package:aibs_app/data/theme_preferences.dart';
import 'package:aibs_app/widgets/theme_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'moon toggle persists dark and light and can restore system mode',
    (tester) async {
      final writes = <String>[];
      final prefs = ThemePreferences(write: (v) async => writes.add(v));
      await prefs.setMode(ThemeMode.light);
      await tester.pumpWidget(
        MaterialApp(
          theme: AibsTheme.light,
          home: Scaffold(body: ThemeToggleCard(preferences: prefs)),
        ),
      );
      await tester.tap(find.byTooltip('Ganti ke tema gelap'));
      await tester.pumpAndSettle();
      expect(prefs.mode, ThemeMode.dark);
      expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
      await tester.tap(find.byTooltip('Ganti ke tema terang'));
      await tester.pumpAndSettle();
      expect(prefs.mode, ThemeMode.light);
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
      await tester.tap(find.text('Ikuti perangkat'));
      await tester.pumpAndSettle();
      expect(prefs.mode, ThemeMode.system);
      expect(writes, ['light', 'dark', 'light', 'system']);
      expect(tester.takeException(), isNull);
    },
  );
}

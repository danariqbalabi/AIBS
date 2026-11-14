import 'package:aibs_app/core/theme/aibs_tokens.dart';
import 'package:aibs_app/data/theme_preferences.dart';
import 'package:aibs_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'theme choice restores and a failed write preserves the previous choice',
    () async {
      String? stored;
      final preferences = ThemePreferences(
        read: () async => stored,
        write: (v) async {
          stored = v;
        },
      );
      await preferences.setMode(ThemeMode.dark);
      final restored = ThemePreferences(read: () async => stored);
      await restored.load();
      expect(restored.mode, ThemeMode.dark);
      final broken = ThemePreferences(
        write: (_) async => throw Exception('storage unavailable'),
      );
      await expectLater(broken.setMode(ThemeMode.dark), throwsException);
      expect(broken.mode, ThemeMode.system);
      expect(broken.saving, false);
    },
  );

  testWidgets(
    'night mode applies to onboarding, profile and capture overlays',
    (tester) async {
      final preferences = ThemePreferences.memory();
      await preferences.setMode(ThemeMode.dark);
      await tester.pumpWidget(AibsApp(themePreferences: preferences));
      await tester.pumpAndSettle();
      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
      expect(
        scaffold.backgroundColor ??
            Theme.of(tester.element(find.byType(Scaffold).first))
                .scaffoldBackgroundColor,
        AibsDarkColors.surface,
      );
      await tester.tap(find.text('Coba Demo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nadia, 21'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tampilan'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Gelap'), findsOneWidget);
      await tester.tap(find.byTooltip('Tambah catatan'));
      await tester.pumpAndSettle();
      final sheetTheme = Theme.of(tester.element(find.byType(BottomSheet)));
      expect(sheetTheme.bottomSheetTheme.backgroundColor, AibsDarkColors.card);
      expect(tester.takeException(), isNull);
      await preferences.setMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(BottomSheet))).brightness,
        Brightness.light,
      );
    },
  );
}

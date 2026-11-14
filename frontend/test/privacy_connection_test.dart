import 'package:aibs_app/pages/home_profile_pages.dart';
import 'package:aibs_app/pages/profile_setup_flow.dart';
import 'package:aibs_app/theme/aibs_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'privacy export uses backend callback and failed deletion keeps the page',
    (tester) async {
      var exports = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AibsTheme.light,
          home: Scaffold(
            body: ProfilePage(
              profile: ProfileSetupAnswers(
                displayName: 'Test',
                email: '',
                ageBand: null,
                diagnosis: null,
                clinicianGuidance: null,
                dietType: null,
                dietPhase: null,
                budget: null,
                spicy: null,
                redFlags: const [],
                pattern: const [],
                avoidedIngredients: const [],
                portionLimits: const {},
                allergies: const [],
                tolerances: const [],
                preferences: const [],
              ),
              onExportData: () async {
                exports++;
              },
              onDeleteAll: () async {
                throw Exception('failed');
              },
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Privasi & AI'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Privasi & AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unduh data saya'));
      await tester.pumpAndSettle();
      expect(exports, 1);
      await tester.tap(find.text('Hapus semua data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus').last);
      await tester.pumpAndSettle();
      expect(find.text('Privasi'), findsOneWidget);
      expect(find.text('Hapus semua data'), findsOneWidget);
    },
  );
}

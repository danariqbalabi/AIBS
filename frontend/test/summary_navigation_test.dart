import 'package:aibs_app/core/demo_data.dart';
import 'package:aibs_app/pages/summary_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    '30 day summary uses server counts and period on pattern detail',
    (tester) async {
      final day = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          home: SummaryPage(
            meals: const [],
            profile: null,
            onOpenJournal: () {},
            symptoms: [
              AibsSymptomLog(
                name: 'Kembung',
                time: '15:00',
                date: day,
                severity: 2,
                mealName: 'Nasi',
              ),
            ],
            loadSummary: (days) async => {
              'status': 'descriptive_only',
              'food_count': 42,
              'symptom_count': 1,
              'daily': [],
              'unknown_composition_count': 0,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 hari'));
      await tester.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
      await tester.tap(find.text('Lihat catatan ›'));
      await tester.pumpAndSettle();
      expect(find.text('Kembung · 30 hari'), findsOneWidget);
      expect(find.text('Setelah Nasi'), findsOneWidget);
      expect(find.text('Sebelum Nasi'), findsNothing);
    },
  );
}

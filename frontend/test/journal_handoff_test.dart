import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aibs_app/core/demo_data.dart';
import 'package:aibs_app/pages/record_pages.dart';
import 'package:aibs_app/theme/aibs_theme.dart';

void main() {
  testWidgets('journal filters meals and symptoms without breaking stories', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: Scaffold(
          body: JournalPage(
            meals: [AibsMealLog(name: 'Nasi ayam', time: '12:00', date: today)],
            symptoms: [
              AibsSymptomLog(
                name: 'Kembung',
                time: '14:00',
                date: today,
                severity: 2,
              ),
            ],
            stories: [
              AibsStoryLog(
                text: 'Makan lalu kembung',
                time: '15:00',
                date: today,
              ),
            ],
            aiEnabled: true,
            onAddMeal: () {},
            onAddSymptom: (_) {},
            onAddStory: (_) {},
            onDeleteMeal: (_) {},
            onOpenSummary: () {},
          ),
        ),
      ),
    );

    expect(find.text('Nasi ayam'), findsOneWidget);
    expect(find.text('Kembung'), findsOneWidget);
    expect(find.text('Cerita hari ini'), findsOneWidget);
    await tester.tap(find.text('Gejala'));
    await tester.pumpAndSettle();
    expect(find.text('Nasi ayam'), findsNothing);
    expect(find.text('Kembung'), findsOneWidget);
    expect(find.text('Cerita hari ini'), findsNothing);
  });

  testWidgets('story draft can be saved, resumed, and discarded', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: Scaffold(
          body: JournalPage(
            meals: const [],
            symptoms: const [],
            stories: const [],
            aiEnabled: true,
            onAddMeal: () {},
            onAddSymptom: (_) {},
            onAddStory: (_) {},
            onDeleteMeal: (_) {},
            onOpenSummary: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Catat').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tulis cerita'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Makan lalu kembung');
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Ceritamu belum disimpan'), findsOneWidget);
    await tester.tap(find.text('Simpan draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan draft cerita'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Makan lalu kembung',
    );

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buang draft'));
    await tester.pumpAndSettle();
    expect(find.text('Lanjutkan draft cerita'), findsNothing);
  });
}

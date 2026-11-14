import 'package:aibs_app/core/demo_data.dart';
import 'package:aibs_app/pages/record_pages.dart';
import 'package:aibs_app/pages/journal_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('journal repeat copies the meal without mutating history', (
    tester,
  ) async {
    final meal = AibsMealLog(
      id: 'original',
      name: 'Nasi uji',
      time: '12:00',
      date: DateTime.now(),
      ingredients: ['Nasi'],
    );
    AibsMealLog? copied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalPage(
            meals: [meal],
            symptoms: [],
            stories: [],
            aiEnabled: false,
            onAddMeal: () {},
            onAddSymptom: (_) {},
            onAddStory: (_) {},
            onDeleteMeal: (_) {},
            onOpenSummary: () {},
            onRepeatMeal: (m) => copied = m,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Nasi uji'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat ulang makanan'));
    await tester.pumpAndSettle();
    expect(copied?.id, 'original');
    expect(meal.name, 'Nasi uji');
  });
  testWidgets('daily timeline exposes symptom severity and opens source day', (
    tester,
  ) async {
    DateTime? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: JournalTimelinePage(
          meals: [],
          symptoms: [
            AibsSymptomLog(
              name: 'Gas',
              time: '13:00',
              date: DateTime.now(),
              severity: 3,
            ),
          ],
          onOpenEvidence: (day, _) => opened = day,
        ),
      ),
    );
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('Belum tentu penyebab'), findsOneWidget);
    await tester.tap(find.text('Gas'));
    expect(opened, isNotNull);
  });
}

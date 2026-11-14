import 'package:aibs_app/core/demo_data.dart';
import 'package:aibs_app/pages/record_pages.dart';
import 'package:aibs_app/theme/aibs_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'a restored photo draft opens its server ID without rerunning AI',
    (tester) async {
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: AibsTheme.light,
          home: Scaffold(
            body: JournalPage(
              meals: const [],
              symptoms: const [],
              stories: [
                AibsStoryLog(
                  text: 'Nasi',
                  time: '12:00',
                  date: DateTime.now(),
                  draftId: 'draft-server-1',
                  version: 2,
                  title: 'Draft foto makanan',
                ),
              ],
              aiEnabled: false,
              onAddMeal: () {},
              onAddSymptom: (_) {},
              onAddStory: (_) {},
              onDeleteMeal: (_) {},
              onOpenSummary: () {},
              onResumeDraft: (id) async {
                opened = id;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Draft foto makanan'));
      await tester.pumpAndSettle();
      expect(opened, 'draft-server-1');
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aibs_app/pages/onboarding_flow.dart';
import 'package:aibs_app/pages/profile_setup_flow.dart';
import 'package:aibs_app/pages/record_pages.dart';
import 'package:aibs_app/theme/aibs_theme.dart';

void main() {
  testWidgets('AI consent is kept when onboarding is deferred', (tester) async {
    ProfileSetupAnswers? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: OnboardingFlow(onComplete: (profile) => saved = profile),
      ),
    );

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'nadia@example.com');
    await tester.tap(find.text('Kirim kode'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 8; index++) {
      await tester.enterText(find.byType(TextField).at(index), '1');
    }
    tester.testTextInput.hide();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tanpa AI'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Berapa usia kamu?'), findsOneWidget);
    await tester.tap(find.text('Nanti'));
    await tester.pumpAndSettle();
    expect(saved?.aiEnabled, isFalse);
  });

  testWidgets('photo preview offers manual entry when AI is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: CameraFlowPage(
          aiEnabled: false,
          onSaved: (_) {},
          onAddSymptom: () {},
        ),
      ),
    );

    await tester.tap(find.text('Ambil foto'));
    await tester.pumpAndSettle();
    expect(find.text('Isi manual'), findsOneWidget);
    expect(find.text('Analisis'), findsNothing);
  });
}

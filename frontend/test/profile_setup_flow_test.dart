import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aibs_app/pages/profile_setup_flow.dart';
import 'package:aibs_app/theme/aibs_theme.dart';

void main() {
  testWidgets('under-18 answer opens the scope screen and can be changed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: ProfileSetupFlow(
          displayName: 'Nadia',
          email: 'nadia@example.com',
          onComplete: (_) {},
          onBackToAccount: () {},
        ),
      ),
    );

    await tester.tap(find.text('Di bawah 18'));
    await tester.pumpAndSettle();
    expect(find.text('AIBS dibuat untuk usia 18+'), findsOneWidget);

    await tester.tap(find.text('Ubah usia'));
    await tester.pumpAndSettle();
    expect(find.text('Berapa usia kamu?'), findsOneWidget);
  });

  testWidgets('active severe answer routes to help before assessment', (
    tester,
  ) async {
    var assessmentCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: ProfileSetupFlow(
          displayName: 'Nadia',
          email: 'nadia@example.com',
          onComplete: (_) {},
          onBackToAccount: () {},
          onAssess: (_) async {
            assessmentCalls++;
            return const ScreeningAssessment(
              route: ScreeningRoute.loggingOnly,
              headline: 'Hasil',
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('18–29'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();

    expect(find.text('Periksa ke dokter dulu, ya'), findsOneWidget);
    expect(find.text('Telepon 119'), findsOneWidget);
    expect(assessmentCalls, 0);
  });

  testWidgets('missing assessor does not calculate a screening result', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: ProfileSetupFlow(
          displayName: 'Nadia',
          email: 'nadia@example.com',
          onComplete: (_) {},
          onBackToAccount: () {},
        ),
      ),
    );

    await tester.tap(find.text('18–29'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidak tahu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 5; index++) {
      await tester.tap(find.text('Tidak'));
      await tester.pumpAndSettle();
    }
    for (var index = 0; index < 6; index++) {
      await tester.tap(find.text('Tidak tahu'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Hasil pengecekan awal belum tersedia'), findsOneWidget);
    expect(find.text('Polanya cocok dengan kriteria IBS'), findsNothing);
    expect(find.text('Mulai catat aja'), findsOneWidget);
  });

  testWidgets('profile answers are assessed, reviewed, editable, and saved', (
    tester,
  ) async {
    ProfileSetupAnswers? saved;
    ScreeningAnswers? submitted;

    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: ProfileSetupFlow(
          displayName: 'Nadia',
          email: 'nadia@example.com',
          onComplete: (answers) => saved = answers,
          onBackToAccount: () {},
          onAssess: (answers) async {
            submitted = answers;
            return const ScreeningAssessment(
              route: ScreeningRoute.dietSupport,
              headline: 'Polanya cocok dengan kriteria IBS',
              criteria: [true, true, true, true],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('18–29'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 5; index++) {
      await tester.tap(find.text(index == 1 ? 'Tidak tahu' : 'Tidak'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3–4 hari'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6–12 bulan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();
    expect(find.text('Polanya cocok dengan kriteria IBS'), findsOneWidget);
    expect(submitted?.ageBand, '18_29');
    expect(submitted?.severeActive, 'no');
    expect(submitted?.bleeding, 'unknown');
    expect(submitted?.bleedingActive, 'unknown');
    expect(submitted?.q1, 'yes');
    expect(submitted?.q2FrequencyBand, '3_4');
    expect(submitted?.q3DurationBand, '6_12');
    expect([submitted?.q4, submitted?.q5, submitted?.q6], ['yes', 'yes', 'no']);

    await tester.tap(find.text('Isi arahan diet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low FODMAP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminasi'));
    await tester.pumpAndSettle();
    expect(find.text('Bawang putih'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Udang'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rp25.000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sedikit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Halal'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Udah bener?'), findsOneWidget);
    expect(find.text('Low FODMAP · eliminasi'), findsOneWidget);

    await tester.tap(find.text('Alergi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kacang tanah'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Udang · Kacang tanah'), findsOneWidget);

    await tester.tap(find.text('Simpan profil'));
    await tester.pumpAndSettle();
    expect(saved?.displayName, 'Nadia');
    expect(saved?.dietType, 'Low FODMAP');
    expect(saved?.dietPhase, 'Eliminasi');
    expect(saved?.allergies, ['Udang', 'Kacang tanah']);
    expect(saved?.preferences, ['Halal']);
  });
}

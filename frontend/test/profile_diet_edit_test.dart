import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aibs_app/pages/home_profile_pages.dart';
import 'package:aibs_app/pages/profile_setup_flow.dart';
import 'package:aibs_app/theme/aibs_theme.dart';

void main() {
  testWidgets('removing an avoided ingredient requires confirmation', (
    tester,
  ) async {
    final initial = _profile();
    ProfileSetupAnswers? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: Scaffold(
          body: ProfilePage(
            profile: initial,
            onProfileSaved: (profile) => saved = profile,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Arahan makan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bawang bombay'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Bawang bombay'));
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Hapus Bawang bombay dari daftar hindari?'),
      findsOneWidget,
    );
    expect(saved, isNull);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(saved, isNull);

    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, ubah'));
    await tester.pumpAndSettle();

    expect(saved?.avoidedIngredients, ['Bawang putih']);
    expect(saved?.dietType, 'Low FODMAP');
    expect(find.text('Bawang putih'), findsOneWidget);
    expect(find.text('Bawang bombay'), findsNothing);
  });

  testWidgets('restoring a removed chip avoids confirmation', (tester) async {
    ProfileSetupAnswers? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: Scaffold(
          body: ProfilePage(
            profile: _profile(),
            onProfileSaved: (profile) => saved = profile,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Arahan makan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bawang bombay'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Bawang bombay'));
    await tester.tap(find.text('Bawang bombay'));
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(saved?.avoidedIngredients, ['Bawang putih', 'Bawang bombay']);
  });

  testWidgets('loosening a portion limit requires confirmation', (
    tester,
  ) async {
    ProfileSetupAnswers? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: Scaffold(
          body: ProfilePage(
            profile: _profile(),
            onProfileSaved: (profile) => saved = profile,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Arahan makan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Kurangi porsi Nasi'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Kurangi porsi Nasi'));
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Longgarkan batas porsi nasi?'), findsOneWidget);
    await tester.tap(find.text('Ya, ubah'));
    await tester.pumpAndSettle();

    expect(saved?.portionLimits['Nasi'], 0);
  });

  testWidgets('adding a portion limit saves without a warning', (tester) async {
    ProfileSetupAnswers? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: Scaffold(
          body: ProfilePage(
            profile: _profile(),
            onProfileSaved: (profile) => saved = profile,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Arahan makan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Tambah porsi Roti'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Tambah porsi Roti'));
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(saved?.portionLimits['Roti'], 1);
  });
}

ProfileSetupAnswers _profile() => ProfileSetupAnswers(
  displayName: 'Nadia',
  email: 'nadia@example.com',
  ageBand: '18–29',
  diagnosis: 'Ya',
  clinicianGuidance: 'Ya',
  redFlags: const [],
  pattern: const [],
  dietType: 'Low FODMAP',
  dietPhase: 'Eliminasi',
  avoidedIngredients: const ['Bawang putih', 'Bawang bombay'],
  portionLimits: const {'Nasi': 1, 'Buah': 1, 'Roti': null},
  allergies: const ['Udang'],
  tolerances: const ['Kopi'],
  budget: 'Rp25.000',
  spicy: 'Sedikit',
  preferences: const ['Halal'],
);

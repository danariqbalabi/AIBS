import 'package:aibs_app/core/demo_data.dart';
import 'package:aibs_app/main.dart';
import 'package:aibs_app/pages/home_profile_pages.dart';
import 'package:aibs_app/pages/profile_setup_flow.dart';
import 'package:aibs_app/pages/record_pages.dart';
import 'package:aibs_app/pages/menu_flow.dart';
import 'package:aibs_app/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProfileSetupAnswers profile() => ProfileSetupAnswers(
  displayName: 'Test',
  email: '',
  ageBand: null,
  diagnosis: null,
  clinicianGuidance: null,
  redFlags: [],
  pattern: [],
  dietType: null,
  dietPhase: null,
  avoidedIngredients: [],
  portionLimits: {},
  allergies: [],
  tolerances: [],
  budget: 'Rp25000',
  spicy: 'Sedikit',
  preferences: [],
  aiEnabled: false,
  serverVersion: 7,
);

void main() {
  testWidgets(
    'conflicting bought menu offers alternatives and confirms consumption',
    (tester) async {
      var recorded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MenuDetailPage(
            item: const AibsMenuItem(
              id: 'bad',
              name: 'Udang',
              kind: 'Beli',
              price: 20000,
              status: CheckStatus.bad,
              reason: 'Ada alergi',
              ingredients: ['Udang'],
              orderTips: ['Tanpa saus'],
            ),
            onAddShopping: (_) {},
            onStartMealRecord: (_) => recorded = true,
            onPlanSaved: (_) {},
          ),
        ),
      );
      expect(find.text('Lihat pilihan sesuai'), findsOneWidget);
      expect(find.text('Masukkan ke checklist belanja'), findsNothing);
      await tester.scrollUntilVisible(find.text('Salin cara pesan'), 150);
      expect(find.text('Salin cara pesan'), findsOneWidget);
      await tester.tap(find.text('Tetap catat'));
      await tester.pumpAndSettle();
      expect(recorded, false);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(recorded, false);
      await tester.tap(find.text('Tetap catat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sudah dimakan'));
      await tester.pumpAndSettle();
      expect(recorded, true);
    },
  );

  testWidgets(
    'without AI the shared entry opens manual input and closes to origin',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AibsHomeShell(profile: profile())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tambah catatan'));
      await tester.pumpAndSettle();
      expect(find.text('Tulis cerita'), findsNothing);
      await tester.tap(find.text('Catat makan'));
      await tester.pumpAndSettle();
      expect(find.text('Nama makanan'), findsOneWidget);
      expect(find.text('Ambil foto'), findsNothing);
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tambah catatan'), findsOneWidget);
      expect(find.text('Ambil foto'), findsNothing);
    },
  );

  testWidgets(
    'symptom after meal selects its exact ID even with duplicate names',
    (tester) async {
      AibsSymptomLog? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: SymptomEntryPage(
            meals: [
              for (final id in ['old', 'saved'])
                AibsMealLog(
                  id: id,
                  name: 'Nasi',
                  time: '12.00',
                  date: DateTime.now(),
                ),
            ],
            initialMealId: 'saved',
            onSave: (value) => saved = value,
          ),
        ),
      );
      await tester.tap(find.text('Kembung'));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(saved?.mealId, 'saved');
    },
  );

  testWidgets(
    'allergy edits persist through the profile callback with version intact',
    (tester) async {
      ProfileSetupAnswers? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              profile: profile(),
              onProfileSaved: (value) => saved = value,
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(find.text('Alergi'), 150);
      await tester.tap(find.text('Alergi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Udang, Kacang');
      await tester.tap(find.text('Simpan perubahan'));
      await tester.pumpAndSettle();
      expect(saved?.allergies, ['Udang', 'Kacang']);
      expect(saved?.serverVersion, 7);
    },
  );

  testWidgets('a failed preference save keeps the entered budget for retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            profile: profile(),
            onProfileSaved: (_) => throw Exception('offline'),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Budget & preferensi'), 150);
    await tester.tap(find.text('Budget & preferensi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '30000');
    await tester.scrollUntilVisible(
      find.text('Simpan perubahan'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('30000'), findsOneWidget);
    expect(find.text('Simpan perubahan'), findsOneWidget);
  });
}

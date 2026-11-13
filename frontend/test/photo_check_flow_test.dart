import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aibs_app/pages/photo_check_flow.dart';
import 'package:aibs_app/shared/widgets/status_badge.dart';

void main() {
  testWidgets('manual entry launched from F0 returns to the previous tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    body: CameraFlowPage(
                      intent: FoodCheckIntent.checkBeforeMeal,
                      initialManualEntry: true,
                    ),
                  ),
                ),
              ),
              child: const Text('Open flow'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open flow'));
    await tester.pumpAndSettle();
    expect(find.text('Nama makanan'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Open flow'), findsOneWidget);
    expect(find.text('Foto dari atas, semua lauk kelihatan'), findsNothing);
  });

  testWidgets('manual flow confirms unknown ingredients before saving', (
    tester,
  ) async {
    FoodCheckDraft? savedDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraFlowPage(
            intent: FoodCheckIntent.checkBeforeMeal,
            initialManualEntry: true,
            onSaveRecord: (draft) => savedDraft = draft,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Isi nama makanan'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Ayam kecap');
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Saus ini kira-kira apa?'), findsOneWidget);

    await tester.tap(find.text('Cek makanan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih saus atau pilih Nggak tahu.'), findsOneWidget);

    await tester.tap(find.text('? Nggak tahu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cek makanan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum bisa dinilai'), findsOneWidget);

    await tester.tap(find.text('Tetap catat'));
    await tester.pumpAndSettle();
    expect(find.text('Tersimpan'), findsOneWidget);
    expect(savedDraft?.name, 'Ayam kecap');
    expect(savedDraft?.ingredients.last.isUnknown, isTrue);
  });

  testWidgets('photo analysis failure offers manual recovery', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraFlowPage(
            intent: FoodCheckIntent.checkBeforeMeal,
            aiEnabled: true,
            onAnalyzePhoto: () => Future<FoodCheckDraft>.error(
              const FoodCheckException('Coba lagi nanti.'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ambil foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analisis'));
    await tester.pumpAndSettle();

    expect(find.text('Fotonya belum bisa dibaca'), findsOneWidget);
    expect(find.text('Coba lagi nanti.'), findsOneWidget);
    await tester.tap(find.text('Isi manual'));
    await tester.pumpAndSettle();
    expect(find.text('Nama makanan'), findsOneWidget);
  });

  testWidgets('AI disabled never runs the photo analyzer', (tester) async {
    var analyzeCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraFlowPage(
            intent: FoodCheckIntent.checkBeforeMeal,
            aiEnabled: false,
            onAnalyzePhoto: () async {
              analyzeCalls++;
              return const FoodCheckDraft(name: 'Ayam kecap', ingredients: []);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ambil foto'));
    await tester.pumpAndSettle();
    expect(find.text('Analisis'), findsNothing);
    await tester.tap(find.text('Isi manual'));
    await tester.pumpAndSettle();

    expect(analyzeCalls, 0);
    expect(find.text('Nama makanan'), findsOneWidget);
  });

  testWidgets('photo draft is reviewed and checked through callbacks', (
    tester,
  ) async {
    FoodCheckDraft? checkedDraft;
    FoodCheckDraft? savedDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraFlowPage(
            intent: FoodCheckIntent.checkBeforeMeal,
            aiEnabled: true,
            onAnalyzePhoto: () async => const FoodCheckDraft(
              name: 'Nasi ayam bakar kecap',
              ingredients: [
                FoodIngredient(name: 'Nasi putih', amount: '1 porsi'),
                FoodIngredient(name: 'Ayam paha', amount: '100 g'),
              ],
            ),
            onCheckFood: (draft) async {
              checkedDraft = draft;
              return const FoodCheckOutcome(
                status: CheckStatus.ok,
                headline: 'Sesuai arahanmu',
                reason: 'Bahan yang dikonfirmasi sesuai profilmu.',
              );
            },
            onSaveRecord: (draft) => savedDraft = draft,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ambil foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analisis'));
    await tester.pumpAndSettle();
    expect(find.text('Cek hasil foto'), findsOneWidget);

    await tester.tap(find.text('Cek makanan'));
    await tester.pumpAndSettle();
    expect(find.text('Sesuai arahanmu'), findsOneWidget);
    expect(checkedDraft?.name, 'Nasi ayam bakar kecap');

    await tester.tap(find.text('Catat sudah dimakan'));
    await tester.pumpAndSettle();
    expect(find.text('Tersimpan'), findsOneWidget);
    expect(savedDraft?.name, 'Nasi ayam bakar kecap');
  });

  testWidgets('already-eaten intent saves after unknown confirmation', (
    tester,
  ) async {
    FoodCheckDraft? savedDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraFlowPage(
            intent: FoodCheckIntent.alreadyEaten,
            initialManualEntry: true,
            onSaveRecord: (draft) => savedDraft = draft,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Sup ayam');
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('? Nggak tahu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Tersimpan'), findsOneWidget);
    expect(savedDraft?.name, 'Sup ayam');
  });
}

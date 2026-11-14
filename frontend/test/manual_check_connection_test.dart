import 'package:aibs_app/pages/record_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('manual consumption requires time confirmation before saving', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraFlowPage(
          initialManualEntry: true,
          initialFoodName: 'Nasi',
          intent: MealIntent.eaten,
          onSaved: (meal) {
            saved = true;
            expect(meal.serverPayload!['time']['confirmed'], true);
          },
          onAddSymptom: () {},
        ),
      ),
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(saved, false);
    await tester.tap(find.text('Konfirmasi sudah dimakan'));
    await tester.pumpAndSettle();
    expect(saved, false);
    await tester.tap(find.text('Waktu sudah ditinjau'));
    await tester.tap(find.text('Konfirmasi sudah dimakan'));
    await tester.pumpAndSettle();
    expect(saved, true);
  });
  testWidgets(
    'food check renders server assessment without logging consumption',
    (tester) async {
      var checked = false;
      var saved = false;
      await tester.pumpWidget(
        MaterialApp(
          home: CameraFlowPage(
            onSaved: (_) {
              saved = true;
            },
            onAddSymptom: () {},
            initialManualEntry: true,
            initialFoodName: 'Ayam bawang',
            initialIngredients: const ['Bawang putih'],
            onCheckFood: (ingredients, complete) async {
              checked = true;
              expect(ingredients, ['Bawang putih']);
              expect(complete, true);
              return {
                'status': 'bad',
                'reasons': [
                  {'message': 'Ada bahan dalam daftar hindari.'},
                ],
                'missing_information': [],
              };
            },
          ),
        ),
      );
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(checked, true);
      expect(saved, false);
      expect(find.text('Tidak sesuai arahan'), findsOneWidget);
      expect(find.text('Ada bahan dalam daftar hindari.'), findsOneWidget);
    },
  );
}

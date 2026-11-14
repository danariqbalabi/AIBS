import 'package:aibs_app/pages/record_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

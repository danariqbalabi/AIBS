import 'package:aibs_app/core/demo_data.dart';
import 'package:aibs_app/pages/menu_flow.dart';
import 'package:aibs_app/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edited ingredient quantity is checked and passed to shopping', (
    tester,
  ) async {
    Map<String, dynamic>? checked;
    AibsMenuItem? shopping;
    await tester.pumpWidget(
      MaterialApp(
        home: MenuDetailPage(
          item: const AibsMenuItem(
            id: 'demo',
            name: 'Nasi',
            kind: 'Beli',
            price: 20000,
            status: CheckStatus.ok,
            reason: 'Sesuai arahan',
            ingredients: ['Nasi · 1 porsi'],
            serverIngredients: [
              {
                'ingredient_id': 'rice',
                'display_name': 'Nasi',
                'quantity': '1',
                'unit': 'porsi',
                'certainty': 'confirmed',
              },
            ],
          ),
          ingredientId: (_) => 'rice',
          onAddShopping: (item) => shopping = item,
          onStartMealRecord: (_) {},
          onPlanSaved: (_) {},
          onCheckMenu: (card) async {
            checked = card;
            return {
              'status': 'warn',
              'reasons': [
                {'message': 'Porsi melebihi batas.'},
              ],
              'missing_information': [],
            };
          },
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Ubah porsi / ganti bahan'), 180);
    await tester.tap(find.text('Ubah porsi / ganti bahan'));
    await tester.pumpAndSettle();
    final amount = find.widgetWithText(TextFormField, 'Jumlah');
    await tester.enterText(amount, '2');
    await tester.tap(find.text('Cek ulang & gunakan'));
    await tester.pumpAndSettle();
    expect(checked!['ingredients'][0]['quantity'], '2');
    await tester.scrollUntilVisible(find.text('Porsi melebihi batas.'), -180);
    expect(find.text('Porsi melebihi batas.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Masukkan ke checklist belanja'),
      180,
    );
    await tester.tap(find.text('Masukkan ke checklist belanja'));
    await tester.pumpAndSettle();
    expect(shopping!.customized, true);
    expect(shopping!.serverIngredients.single['quantity'], '2');
  });
}

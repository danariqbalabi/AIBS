import 'package:aibs_app/widgets/record_card_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<Map<String, dynamic>> _catalog = [
  {
    'id': 'chicken-id',
    'name': 'Ayam',
    'aliases': ['ayam paha'],
  },
  {
    'id': 'rice-id',
    'name': 'Nasi putih',
    'aliases': ['nasi'],
  },
];

String? _lookup(String name) {
  final needle = name.trim().toLowerCase();
  for (final row in _catalog) {
    final names = [row['name'], ...row['aliases'] as List];
    if (names.any((n) => n.toString().toLowerCase() == needle)) {
      return row['id'] as String;
    }
  }
  return null;
}

Future<Map<String, dynamic>> _pump(
  WidgetTester tester,
  Map<String, dynamic> ingredient, {
  List<Map<String, dynamic>> catalog = _catalog,
}) async {
  final card = <String, dynamic>{
    'name': 'Ayam goreng',
    'consumed': true,
    'ingredients': [ingredient],
    'ingredients_complete': false,
  };
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          IngredientCatalogScope(items: () => catalog, child: child!),
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecordCardForm(
            kind: 'food',
            value: card,
            ingredientId: _lookup,
            showConsumptionAndTime: false,
          ),
        ),
      ),
    ),
  );
  return card;
}

Finder get _confirmBox =>
    find.widgetWithText(CheckboxListTile, 'Bahan dikonfirmasi');

void main() {
  testWidgets('catalog match confirms immediately', (tester) async {
    final row = <String, dynamic>{
      'display_name': 'nasi',
      'ingredient_id': 'rice-id',
      'certainty': 'candidate',
    };
    await _pump(tester, row);
    await tester.tap(_confirmBox);
    await tester.pumpAndSettle();
    expect(row['certainty'], 'confirmed');
    expect(row['ingredient_id'], 'rice-id');
    expect(tester.widget<CheckboxListTile>(_confirmBox).value, isTrue);

    await tester.tap(_confirmBox);
    await tester.pumpAndSettle();
    expect(row['certainty'], 'candidate');
  });

  testWidgets(
    'unmatched AI name opens catalog picker instead of snapping back',
    (tester) async {
      final row = <String, dynamic>{
        'display_name': 'ayam goreng',
        'ingredient_id': null,
        'certainty': 'unknown',
      };
      await _pump(tester, row);
      await tester.tap(_confirmBox);
      await tester.pumpAndSettle();
      expect(find.text('"ayam goreng" belum ada di katalog'), findsOneWidget);

      await tester.tap(find.text('Ayam'));
      await tester.pumpAndSettle();
      expect(row['ingredient_id'], 'chicken-id');
      expect(row['certainty'], 'confirmed');
      expect(row['display_name'], 'ayam goreng');
      expect(tester.widget<CheckboxListTile>(_confirmBox).value, isTrue);
      expect(find.textContaining('Cocok dengan katalog: Ayam'), findsOneWidget);
    },
  );

  testWidgets('cancelling the picker leaves the ingredient unconfirmed', (
    tester,
  ) async {
    final row = <String, dynamic>{
      'display_name': 'saus gelap',
      'ingredient_id': null,
      'certainty': 'unknown',
    };
    await _pump(tester, row);
    await tester.tap(_confirmBox);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(row['certainty'], 'unknown');
    expect(row['ingredient_id'], isNull);
  });

  testWidgets('renaming a confirmed ingredient clears the confirmation', (
    tester,
  ) async {
    final row = <String, dynamic>{
      'display_name': 'nasi',
      'ingredient_id': 'rice-id',
      'certainty': 'confirmed',
    };
    await _pump(tester, row);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama bahan'),
      'nasi goreng',
    );
    await tester.pump();
    expect(row['certainty'], 'unknown');
    expect(tester.widget<CheckboxListTile>(_confirmBox).value, isFalse);
  });

  testWidgets('missing catalog explains why confirmation is unavailable', (
    tester,
  ) async {
    final row = <String, dynamic>{
      'display_name': 'kecap',
      'ingredient_id': null,
      'certainty': 'unknown',
    };
    await _pump(tester, row, catalog: const []);
    await tester.tap(_confirmBox);
    await tester.pumpAndSettle();
    expect(find.text('Katalog bahan belum tersedia'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(row['certainty'], 'unknown');
  });
}

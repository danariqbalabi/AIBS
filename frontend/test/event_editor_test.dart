import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/pages/event_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'a conflict keeps edited text and does not overwrite source card',
    (tester) async {
      final original = <String, dynamic>{
        'id': 'food-1',
        'kind': 'food',
        'version': 1,
        'payload': {
          'name': 'Nama awal',
          'consumed': true,
          'ingredients': [],
          'ingredients_complete': false,
          'time': {
            'date': '2026-11-14',
            'period': 'midday',
            'precision': 'approximate',
            'confirmed': true,
          },
        },
      };
      await tester.pumpWidget(
        MaterialApp(
          home: EventEditorPage(
            event: original,
            onSave: (event) async {
              expect(event['version'], 1);
              expect(event['payload']['name'], 'Nama koreksi');
              throw const ApiFailure(
                'Catatan berubah. Muat ulang.',
                status: 409,
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'Nama koreksi');
      await tester.tap(find.text('Simpan perubahan'));
      await tester.pumpAndSettle();
      expect(find.text('Catatan berubah. Muat ulang.'), findsOneWidget);
      expect(find.text('Nama koreksi'), findsOneWidget);
      expect((original['payload'] as Map)['name'], 'Nama awal');
    },
  );
}

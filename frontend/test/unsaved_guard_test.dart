import 'package:aibs_app/widgets/unsaved_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('back keeps edits until a draft is saved successfully', (
    tester,
  ) async {
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UnsavedGuard(
                    isDirty: () => true,
                    onSaveDraft: () async {
                      saves++;
                    },
                    child: Scaffold(
                      appBar: AppBar(title: const Text('Review')),
                      body: const Text('Isian belum disimpan'),
                    ),
                  ),
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut isi'));
    await tester.pumpAndSettle();
    expect(find.text('Isian belum disimpan'), findsOneWidget);
    expect(saves, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan draft'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(find.text('Buka'), findsOneWidget);
  });
}
